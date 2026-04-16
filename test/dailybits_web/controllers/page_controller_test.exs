defmodule DailybitsWeb.PageControllerTest do
  use DailybitsWeb.ConnCase

  test "GET / renders the library LiveView", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Library"
    assert html_response(conn, 200) =~ "Books synced to Dailybits"
  end
end
