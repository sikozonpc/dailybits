defmodule Dailybits.Repo.Migrations.CreateHighlights do
  use Ecto.Migration

  def change do
    create table(:highlights, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :highlight_id, :string
      add :text, :string
      add :note, :string
      add :location, :string
      add :color, :string
      add :last_accessed, :utc_datetime
      add :book_id, references(:books, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:highlights, [:highlight_id])
    create index(:highlights, [:book_id])
  end
end
