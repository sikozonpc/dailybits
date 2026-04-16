defmodule DailybitsWeb.HighlightJSON do
  alias Dailybits.Library.Highlight

  @doc """
  Random daily insights (same shape as index, with status wrapper).
  """
  def daily(%{highlights: highlights}) do
    %{status: "success", data: for(highlight <- highlights, do: data(highlight))}
  end

  @doc """
  Renders a list of highlights.
  """
  def index(%{highlights: highlights}) do
    %{data: for(highlight <- highlights, do: data(highlight))}
  end

  @doc """
  Renders a single highlight.
  """
  def show(%{highlight: highlight}) do
    %{data: data(highlight)}
  end

  defp data(%Highlight{} = highlight) do
    %{
      id: highlight.id,
      book_id: highlight.book_id,
      highlight_id: highlight.highlight_id,
      text: highlight.text,
      note: highlight.note,
      location: highlight.location,
      color: highlight.color,
      last_accessed: highlight.last_accessed
    }
  end
end
