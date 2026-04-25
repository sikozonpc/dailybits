defmodule Dailybits.Automations.Workers.RunWorker do
  use Oban.Worker, queue: :automations, max_attempts: 3

  alias Dailybits.Automations
  alias Dailybits.Automations.Runner

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"automation_id" => _id}}) do
    automation = Automations.get_singleton()

    result = Runner.run(automation)

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
