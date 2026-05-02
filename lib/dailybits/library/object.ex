defmodule Dailybits.Library.Object do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "objects" do
    field :type, :string
    field :content, :string
    field :title, :string
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(object, attrs) do
    object
    |> cast(attrs, [:type, :content, :title, :metadata])
    |> validate_required([:type, :content, :title])
  end
end
