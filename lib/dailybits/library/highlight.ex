defmodule Dailybits.Library.Highlight do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "highlights" do
    field :highlight_id, :string
    field :text, :string
    field :note, :string
    field :location, :string
    field :color, :string
    field :last_accessed, :utc_datetime

    belongs_to :book, Dailybits.Library.Book

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(highlight, attrs) do
    highlight
    |> cast(attrs, [:highlight_id, :text, :note, :location, :color, :last_accessed, :book_id])
    |> validate_required([
      :highlight_id,
      :text,
      :note,
      :location,
      :color,
      :last_accessed,
      :book_id
    ])
    |> foreign_key_constraint(:book_id)
    |> unique_constraint(:highlight_id)
  end
end
