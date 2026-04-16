defmodule Dailybits.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def change do
    create table(:books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :asin, :string
      add :title, :string
      add :author, :string
      add :cover, :string
      add :last_accessed, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:books, [:asin])
  end
end
