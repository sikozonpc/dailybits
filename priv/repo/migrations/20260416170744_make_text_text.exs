defmodule Dailybits.Repo.Migrations.MakeTextText do
  use Ecto.Migration

  def change do
    alter table(:highlights) do
      modify :text, :text, from: :string
    end
  end
end
