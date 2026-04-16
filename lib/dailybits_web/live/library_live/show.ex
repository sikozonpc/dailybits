defmodule DailybitsWeb.LibraryLive.Show do
  use DailybitsWeb, :live_view

  alias Dailybits.Library

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Library.fetch_book_with_highlights(id) do
      {:ok, book} ->
        {:ok,
         socket
         |> assign(:page_title, book.title)
         |> assign(:book, book)}

      :error ->
        {:ok,
         socket
         |> put_flash(:error, "Book not found")
         |> push_navigate(to: ~p"/library")}
    end
  end

  @doc "Hex accent (dot / border) used for a highlight's color."
  def highlight_color(color), do: highlight_palette(color) |> elem(0)

  @doc "Soft Notion-style background tint for a highlight's color."
  def highlight_bg(color), do: highlight_palette(color) |> elem(1)

  defp highlight_palette(color) when is_binary(color) do
    case String.downcase(String.trim(color)) do
      "yellow" -> {"#cb912f", "#fbf3db"}
      "blue" -> {"#337ea9", "#ddebf1"}
      "pink" -> {"#ad1a72", "#f4dfeb"}
      "orange" -> {"#d9730d", "#faebdd"}
      "red" -> {"#e03e3e", "#fbe4e4"}
      "green" -> {"#448361", "#dbeddb"}
      "purple" -> {"#9065b0", "#eae4f2"}
      _ -> {"#787774", "#f1f1ef"}
    end
  end

  defp highlight_palette(_), do: {"#787774", "#f1f1ef"}
end
