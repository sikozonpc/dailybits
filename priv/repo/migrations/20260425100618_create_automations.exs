defmodule Dailybits.Repo.Migrations.CreateAutomations do
  use Ecto.Migration

  def change do
    create table(:automations) do
      add :name, :string, default: "Default", null: false
      add :enabled, :boolean, default: true, null: false
      add :timezone, :string, default: "Etc/UTC", null: false
      add :graph, :map, default: %{}, null: false
      add :next_run_at, :utc_datetime
      add :last_run_at, :utc_datetime
      add :last_run_status, :string
      add :last_run_error, :text

      timestamps(type: :utc_datetime)
    end

    create index(:automations, [:enabled, :next_run_at])
  end
end
