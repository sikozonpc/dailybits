defmodule Dailybits.Repo.Migrations.RemoveNextRunAt do
  use Ecto.Migration

  def change do
    alter table(:automations) do
      remove :next_run_at, :utc_datetime
    end
  end
end
