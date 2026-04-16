defmodule DailybitsWeb.LibraryLive.ShowTest do
  use DailybitsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Dailybits.LibraryFixtures

  test "renders book and highlights", %{conn: conn} do
    book = book_fixture(%{title: "Show Page Book"})
    highlight_fixture(%{book_id: book.id, text: "Highlight body on show"})

    {:ok, _lv, html} = live(conn, ~p"/books/#{book.id}")
    assert html =~ "Show Page Book"
    assert html =~ "Highlight body on show"
    assert html =~ ~p"/library"
  end

  test "redirects to library when book does not exist", %{conn: conn} do
    missing_id = Ecto.UUID.generate()

    assert {:error, {:live_redirect, %{to: "/library"}}} = live(conn, ~p"/books/#{missing_id}")
  end
end
