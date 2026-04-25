defmodule Dailybits.Automations do
  @moduledoc """
  The Automations context.
  """

  import Ecto.Query, warn: false
  alias Dailybits.Repo
  alias Dailybits.Automations.Workers.RunWorker
  alias Dailybits.Automations.Automation

  def get_singleton do
    Repo.one(from a in Automation, order_by: [asc: a.id], limit: 1)
  end

  def upsert_singleton(attrs) do
    case get_singleton() do
      nil -> %Automation{}
      existing -> existing
    end
    |> Automation.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def enqueue_run(%Automation{} = automation) do
    %{automation_id: automation.id}
    |> RunWorker.new(unique: [period: 30, fields: [:worker, :args]])
    |> Oban.insert()
  end

  def record_result(%Automation{} = automation, status, error \\ nil) do
    automation
    |> Automation.changeset(%{
      last_run_at: DateTime.utc_now(),
      last_run_status: status,
      last_run_error: error
    })
    |> Repo.update()
  end
end
