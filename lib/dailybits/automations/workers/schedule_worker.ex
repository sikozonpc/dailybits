defmodule Dailybits.Automations.Workers.SchedulerWorker do
  use Oban.Worker, queue: :automations

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    :ok
  end
end
