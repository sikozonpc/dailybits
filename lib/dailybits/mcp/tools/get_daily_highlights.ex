defmodule Dailybits.Mcp.Tools.GetDailyHighlights do
  @moduledoc "Returns the daily highlights"

  use Anubis.Server.Component, type: :tool

  alias Dailybits.Library
  alias Anubis.Server.Response

  schema do
    field :count, :integer,
      required: true,
      min_length: 1,
      max_length: 20,
      default: 5,
      description: "the number of highlights to return"
  end

  @impl true
  def execute(%{count: count}, frame) do
    highlights = count |> Library.get_random_highlights() |> Enum.map(&serialize/1)
    response = Response.tool() |> Response.json(%{status: "ok", count: length(highlights)})

    {:reply, Response.json(response, %{highlights: highlights}), frame}
  end

  defp serialize(%Library.Highlight{} = h) do
    %{
      id: h.id,
      text: h.text,
      note: h.note,
      location: h.location,
      color: h.color,
      last_accessed: h.last_accessed,
      book: serialize_book(h.book)
    }
  end

  defp serialize_book(%Library.Book{} = b) do
    %{id: b.id, title: b.title, author: b.author, asin: b.asin, cover: b.cover}
  end

  defp serialize_book(_), do: nil
end
