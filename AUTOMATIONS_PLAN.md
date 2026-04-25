# Automations — End-to-End Flow (Persist, Run, Schedule, Email)

## Context

`DailybitsWeb.AutomationLive` at `/automations` already renders a canvas where the user drags **primitives** (`highlights`, `email`, `notion`), wires them with connections, and edits per-node config in a side panel. Everything lives in socket assigns — reload and it's gone. There is no `Automations` schema, context, runner, scheduler, or email template yet.

This plan closes the loop: **persist one automation, execute it on demand, schedule recurring runs, and send an email with random highlights** when a `highlights → email` subgraph is present. `Dailybits.Library.get_random_highlights/1` and `Dailybits.Mailer` (Swoosh Local adapter) already exist and will be reused as-is.

## High-Level Architecture

```
┌───────────────────────────────────────────────────────────────┐
│  Browser — AutomationLive                                      │
│  canvas UI + [Save] [Run now] + last/next run status label    │
└─────────────┬──────────────────────────────────▲───────────────┘
              │ save / run_now events            │ PubSub updates
              ▼                                  │
┌───────────────────────────────────────────────────────────────┐
│  Dailybits.Automations (context)                              │
│  get_singleton/0 · upsert_singleton/1 · enqueue_run/1         │
│  record_result/3 · compute_next_run_at/2                      │
└─────────────┬──────────────────────────────────▲───────────────┘
              │                                  │
              ▼                                  │
┌──────────────────────────┐   ┌──────────────────────────────────┐
│  Oban (Postgres-backed)   │   │  Automations.Runner (pure)       │
│  queue :automations       │──▶│  resolve_subgraph → gather → dispatch │
│  Plugins.Cron:            │   │  {:ok, summary} | :noop | :error │
│    SchedulerWorker */1m   │   └──────────┬───────────────────────┘
│  RunWorker (max_attempts 3)│             │
└───────────────────────────┘              ▼
                                ┌───────────────────────────┐
                                │ Library.get_random_highlights/1 │
                                │ AutomationEmail → Mailer  │
                                │     (Swoosh Local / prod) │
                                └───────────────────────────┘
```

**Why this shape**
- Oban fits perfectly: Postgres-backed so schedules survive restarts, built-in retries/uniqueness/telemetry, Cron plugin supplies the heartbeat. No need to hand-roll a scheduler or pull in Quantum (in-memory only).
- JSONB `graph` column instead of normalizing into `automation_nodes` / `automation_connections` — the graph is always read/written whole from one LiveView, never queried across, and the shape is still evolving.
- Oban Cron config is static at compile time, so the cron heartbeat only triggers a `SchedulerWorker` that reads user-editable `next_run_at` values from the DB. Schedules are recomputed on save and after each run.

## Data Model

Migration: `priv/repo/migrations/<ts>_create_automations.exs`
```elixir
create table(:automations) do
  add :name,            :string,  null: false, default: "Default"
  add :enabled,         :boolean, null: false, default: true
  add :timezone,        :string,  null: false, default: "Etc/UTC"
  add :graph,           :map,     null: false, default: %{}
  add :next_run_at,     :utc_datetime
  add :last_run_at,     :utc_datetime
  add :last_run_status, :string      # "ok" | "error" | "noop"
  add :last_run_error,  :text
  timestamps(type: :utc_datetime)
end
create index(:automations, [:enabled, :next_run_at])
```
Plus a separate `mix ecto.gen.migration add_oban` migration (standard Oban tables).

`graph` JSON shape (mirrors current assigns, list-shaped for round-trip):
```json
{
  "nodes":       [{"id":1,"type":"highlights","x":150,"y":200,"config":{"scope":"daily"}}],
  "connections": [{"from":1,"to":2}],
  "next_id":     3
}
```

Keep it a regular table (not literally a singleton). `get_singleton/0` is `Repo.one(from a in Automation, order_by: [asc: a.id], limit: 1)` so it's trivial to evolve later.

## Files to Create

- `lib/dailybits/automations.ex` — context: `get_singleton/0`, `upsert_singleton/1`, `enqueue_run/1`, `record_result/3`, `changeset/2`. `enqueue_run` uses `unique: [period: 30, fields: [:worker, :args]]` so a scheduler tick + manual "Run now" collision can't double-fire.
- `lib/dailybits/automations/automation.ex` — Ecto schema + changeset.
- `lib/dailybits/automations/schedule.ex` — pure `compute_next_run_at(graph, now_utc) :: DateTime.t | nil`. Parses first email node's `occurrence` + `time` (UTC v1; see Open Choice E). Pass `now` in so it's table-test-friendly.
- `lib/dailybits/automations/runner.ex` — pure module:
  - `resolve_subgraph/1` — for each email node, walk connections upstream (visited-set to guard cycles) collecting highlights nodes. Notion nodes are ignored with a warning log. **No email node → `{:noop, :no_email_node}`. Email with no upstream highlights → `{:noop, :no_inputs}`** (never send an empty email).
  - `gather_inputs/1` — calls `Library.get_random_highlights(count)` where `count` is the email node's `highlights_count` (cap, not sum) and dedupes by highlight `id` when multiple highlights nodes feed one email.
  - `dispatch/1` — builds `AutomationEmail.highlights_digest/3` and `Mailer.deliver/1`.
  - Return: `{:ok, summary} | {:noop, reason} | {:error, reason}`.
- `lib/dailybits/automations/workers/run_worker.ex` — Oban worker, `queue: :automations`, `max_attempts: 3`. Loads automation, calls `Runner.run/1`, calls `Automations.record_result/3`, broadcasts `{:run_completed, summary}` on `"automation:#{id}"` PubSub topic. Even on error after max attempts, recomputes `next_run_at` so one bad run doesn't permanently stop scheduling.
- `lib/dailybits/automations/workers/scheduler_worker.ex` — Oban worker triggered every minute by Cron plugin. In a single transaction: finds rows where `enabled AND next_run_at IS NOT NULL AND next_run_at <= now()`, nulls `next_run_at`, enqueues `RunWorker`. Insert uses `unique: [period: 55]`.
- `lib/dailybits/automations/automation_email.ex` — builds `%Swoosh.Email{}` with HTML + plain-text bodies. Styling mirrors `daily_live.html.heex`'s Notion-color tints.
- `lib/dailybits/automations/templates/highlights_digest.html.eex` and `.text.eex`.
- Tests (see Testing section below).

## Files to Modify

- `mix.exs` — add `{:oban, "~> 2.18"}`.
- `config/config.exs` — Oban config:
  ```elixir
  config :dailybits, Oban,
    repo: Dailybits.Repo,
    queues: [automations: 3],
    plugins: [
      Oban.Plugins.Pruner,
      {Oban.Plugins.Cron,
        crontab: [{"* * * * *", Dailybits.Automations.Workers.SchedulerWorker}]}
    ]
  ```
  Also set `config :dailybits, Dailybits.Mailer, from: {"Dailybits", "noreply@dailybits.local"}`.
- `config/test.exs` — `config :dailybits, Oban, testing: :manual`.
- `lib/dailybits/application.ex` — add `{Oban, Application.fetch_env!(:dailybits, Oban)}` to the supervision tree (after `Dailybits.Repo`).
- `lib/dailybits_web/live/automation_live.ex`:
  - `mount/3` hydrates from `Automations.get_singleton/0` (graph JSON → socket assigns via `from_storage/1`). Subscribe to `"automation:#{id}"` when an automation exists.
  - Add `handle_event("save", _, socket)` → `upsert_singleton(%{graph: to_storage(assigns), ...})`, then `record_result/3`-equivalent call to recompute `next_run_at` via `Schedule.compute_next_run_at/2`, flash `"Saved"`.
  - Add `handle_event("run_now", _, socket)` — if nothing persisted yet, auto-save first. Then `enqueue_run(automation)`, flash `"Queued"`. Flip an `assigns.running?` flag; clear on `{:run_completed, _}` PubSub message.
  - Add `handle_info({:run_completed, summary}, socket)` to refresh `last_run_at` / `last_run_status`.
- `lib/dailybits_web/live/automation_live.html.heex` — small toolbar above the canvas with `Save` / `Run now` buttons and a compact "Last run: … · Next run: …" label. Run-now button disabled while `@running?`.

## Graph Semantics (v1)

| Case | Behavior |
|---|---|
| No email node | `{:noop, :no_email_node}` |
| Email with no upstream highlights | `{:noop, :no_inputs}` (don't send empty email) |
| Multiple highlights nodes → same email | Union by highlight `id`, then `Enum.take(count)` where count is the email node's `highlights_count` |
| Notion node | Skipped with warning log; out of scope for MVP |
| Cycle in graph | Guarded by visited-set during traversal |
| Invalid schedule config | `compute_next_run_at` returns `nil` (automation still saves, just won't auto-run) |

## Open Choices I'm Making (flag if any are wrong)

- **Time zones (E):** v1 interprets `time: "HH:MM"` as **UTC**. The `timezone` column is added now (default `"Etc/UTC"`) so we can fix this later without a migration. UI label should read `Time (UTC)`.
- **Missed runs on boot:** skip-missed — if the app was down across a scheduled time, we simply recompute forward rather than firing immediately.
- **Notion node:** deliberately out of scope; Runner logs and ignores.

## Implementation Order (each step is smoke-testable)

1. **Persistence only** — migration + schema + `get_singleton` / `upsert_singleton` + LiveView Save button + mount hydration. Smoke test: reload `/automations`, graph survives.
2. **Email + Runner (offline)** — `AutomationEmail` + templates + `Runner.run/1` using `Swoosh.Adapters.Local`. Smoke test: `iex> Dailybits.Automations.Runner.run(Dailybits.Automations.get_singleton())` → email lands in `/dev/mailbox`.
3. **Run Now** — add Oban dep + `RunWorker` + button + PubSub. Smoke test: click Run Now, watch `/dev/mailbox` + live status update.
4. **Scheduling** — `Schedule.compute_next_run_at/2`, recompute on save + after run, `SchedulerWorker` via Cron. Smoke test: save with `time` 2 minutes in the future, wait, observe run.
5. **Polish** — error-path recording, noop flash messages, Run-Now disabled while running, (UTC) label.

## Testing Strategy

**Pure unit tests (fast, no DB, no Oban):**
- `Schedule.compute_next_run_at/2` — table-driven: daily/weekly/monthly, time already passed today, missing/invalid config.
- `Runner.resolve_subgraph/1` — synthetic graphs: no email, email with no inputs, multiple highlights upstream (dedupe + cap), cycles, notion nodes ignored.
- LiveView `to_storage/1` ↔ `from_storage/1` round-trip.

**Integration (DB + `Oban.Testing` + `Swoosh.Test`):**
- Context: `upsert_singleton` inserts then updates the same row.
- `RunWorker.perform/1` end-to-end: seed highlights → drain queue → `assert_email_sent` → assert `last_run_at` / `last_run_status` / new `next_run_at`.
- `SchedulerWorker.perform/1`: past `next_run_at` enqueues once; future doesn't; disabled doesn't.
- Failure path: make `Mailer.deliver/1` raise; assert retries + `last_run_status = "error"` + `next_run_at` still advances.

**LiveView (`Phoenix.LiveViewTest`):**
- Mount hydrates from DB.
- Save persists graph.
- Run Now enqueues (`assert_enqueued worker: RunWorker`).
- PubSub broadcast updates the toolbar label.

**Skipped for v1:** canvas drag browser tests, property-based graph tests.

## End-to-End Verification

1. `mix deps.get && mix ecto.migrate`
2. `mix phx.server`, open `/automations`.
3. Drag a **Highlights** node + an **Email** node, set address + count, connect them.
4. Click **Save** — reload page, graph should still be there.
5. Click **Run Now** — open `/dev/mailbox`, see the digest with N random highlights.
6. Set `time` to ~2 minutes in the future (UTC) and click Save; wait; second email arrives.
7. `iex> Dailybits.Repo.get!(Dailybits.Automations.Automation, id)` — confirm `last_run_at` and `next_run_at` advanced.

## Critical Files

- `lib/dailybits/automations.ex`
- `lib/dailybits/automations/runner.ex`
- `lib/dailybits/automations/schedule.ex`
- `lib/dailybits/automations/workers/run_worker.ex`
- `lib/dailybits/automations/workers/scheduler_worker.ex`
- `lib/dailybits_web/live/automation_live.ex`
- `lib/dailybits/application.ex`
- `mix.exs`, `config/config.exs`, `config/test.exs`
