defmodule Dailybits.Library.Book do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "books" do
    field :asin, :string
    field :title, :string
    field :author, :string
    field :cover, :string
    field :last_accessed, :utc_datetime

    has_many :highlights, Dailybits.Library.Highlight

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [:asin, :title, :author, :cover, :last_accessed])
    |> validate_required([:asin, :title, :author, :last_accessed])
    |> default_cover()
    |> validate_length(:cover, max: 2048)
    |> unique_constraint(:asin)
  end

  defp default_cover(changeset) do
    case get_field(changeset, :cover) do
      nil -> put_change(changeset, :cover, "")
      _ -> changeset
    end
  end
end
