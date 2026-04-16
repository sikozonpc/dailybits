defmodule DailybitsWeb.LibraryLive.IndexTest do
  use DailybitsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Dailybits.LibraryFixtures

  test "renders empty state when there are no books", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/library")
    assert html =~ "No books yet"
  end

  test "lists books with links to the book page", %{conn: conn} do
    book = book_fixture(%{title: "Linked Book Title"})
    highlight_fixture(%{book_id: book.id, text: "Snippet only on show page"})

    {:ok, _lv, html} = live(conn, ~p"/library")
    assert html =~ "Linked Book Title"
    assert html =~ "/books/#{book.id}"
    refute html =~ "Snippet only on show page"
  end
end
