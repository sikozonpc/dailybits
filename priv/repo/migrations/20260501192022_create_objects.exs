defmodule Dailybits.Repo.Migrations.CreateObjects do
  use Ecto.Migration

  def change do
    create table(:objects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :content, :string
      add :title, :string
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end
  end
end
