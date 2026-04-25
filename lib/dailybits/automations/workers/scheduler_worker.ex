defmodule Dailybits.Automations.Workers.SchedulerWorker do
  use Oban.Worker, queue: :automations

  import Ecto.Query

  alias Dailybits.Repo
  alias Dailybits.Automations
  alias Dailybits.Automations.Automation

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    now = DateTime.utc_now()

    due_automations =
      Repo.all(
        from a in Automation,
          where: a.enabled == true and not is_nil(a.next_run_at) and a.next_run_at <= ^now
      )

    Repo.transaction(fn ->
      Enum.each(due_automations, fn automation ->
        # Null out next_run_at so this minute's tick doesn't re-enqueue
        Repo.update_all(
          from(a in Automation, where: a.id == ^automation.id),
          set: [next_run_at: nil]
        )

        Automations.enqueue_run(automation)
      end)
    end)

    :ok
  end
end
