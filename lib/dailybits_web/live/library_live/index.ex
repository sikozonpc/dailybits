defmodule DailybitsWeb.LibraryLive.Index do
  use DailybitsWeb, :live_view

  alias Dailybits.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Library")
     |> assign_books()}
  end

  defp assign_books(socket) do
    assign(socket, :books, Library.list_books_with_highlights())
  end
end
