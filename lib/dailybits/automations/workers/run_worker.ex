defmodule Dailybits.Automations.Workers.RunWorker do
require Logger
  use Oban.Worker, queue: :automations, max_attempts: 3

  alias Dailybits.Automations
  alias Dailybits.Automations.Runner

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"automation_id" => id}}) do
    automation = Automations.get_by_id!(id)

    Logger.info("RunWorker: Starting run for automation #{automation.id} (#{automation.name})")

    result = Runner.run(automation)

    Logger.info("RunWorker: Completed run for automation #{automation.id} with result #{inspect(result)}")

    {status, error} =
      case result do
        {:ok, _} -> {"ok", nil}
        {:noop, reason} -> {"noop", inspect(reason)}
        {:error, reason} -> {"error", inspect(reason)}
      end

    Automations.record_result(automation, status, error)

    Phoenix.PubSub.broadcast(
      Dailybits.PubSub,
      "automation:#{automation.id}",
      {:run_completed, %{status: status, error: error}}
    )

    :ok
  end
end
