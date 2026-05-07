defmodule Dailybits.Automations.Automation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "automations" do
    field :name, :string, default: "Default"
    field :enabled, :boolean, default: true
    field :timezone, :string, default: "Etc/UTC"
    field :graph, :map, default: %{}
    field :last_run_at, :utc_datetime
    field :last_run_status, :string
    field :last_run_error, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(automation, attrs) do
    automation
    |> cast(attrs, [
      :name,
      :enabled,
      :timezone,
      :graph,
      :last_run_at,
      :last_run_status,
      :last_run_error
    ])
    |> validate_required([
      :name,
      :enabled,
      :timezone,
      :graph
    ])
  end
end
