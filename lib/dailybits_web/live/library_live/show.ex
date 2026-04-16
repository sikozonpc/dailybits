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
         |> push_navigate(to: ~p"/")}
    end
  end

  @doc false
  def highlight_color(color) when is_binary(color) do
    case String.downcase(String.trim(color)) do
      "yellow" -> "#ca8a04"
      "blue" -> "#2563eb"
      "pink" -> "#db2777"
      _ -> "#94a3b8"
    end
  end
end
