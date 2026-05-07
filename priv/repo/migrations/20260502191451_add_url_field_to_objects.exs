defmodule Dailybits.Repo.Migrations.AddUrlFieldToObjects do
  use Ecto.Migration

  def change do
    alter table(:objects) do
      add :url, :string
    end
  end
end
