defmodule DailybitsWeb.PageControllerTest do
  use DailybitsWeb.ConnCase

  test "GET / renders the Morning Read page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Morning Read"
    assert html_response(conn, 200) =~ "/library"
  end
end
