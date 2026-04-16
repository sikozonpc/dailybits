defmodule DailybitsWeb.HighlightControllerTest do
  use DailybitsWeb.ConnCase

  import Dailybits.LibraryFixtures
  alias Dailybits.Library.Highlight

  @create_attrs %{
    location: "some location",
    text: "some text",
    color: "some color",
    highlight_id: "some highlight_id",
    note: "some note",
    last_accessed: ~U[2026-04-15 11:57:00Z]
  }
  @update_attrs %{
    location: "some updated location",
    text: "some updated text",
    color: "some updated color",
    highlight_id: "some updated highlight_id",
    note: "some updated note",
    last_accessed: ~U[2026-04-16 11:57:00Z]
  }
  @invalid_attrs %{
    book_id: nil,
    location: nil,
    text: nil,
    color: nil,
    highlight_id: nil,
    note: nil,
    last_accessed: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all highlights", %{conn: conn} do
      conn = get(conn, ~p"/api/highlights")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create highlight" do
    test "renders highlight when data is valid", %{conn: conn} do
      book = book_fixture()
      attrs = Map.put(@create_attrs, :book_id, book.id)

      conn = post(conn, ~p"/api/highlights", highlight: attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/highlights/#{id}")

      book_id = book.id

      assert %{
               "id" => ^id,
               "book_id" => ^book_id,
               "color" => "some color",
               "highlight_id" => "some highlight_id",
               "last_accessed" => "2026-04-15T11:57:00Z",
               "location" => "some location",
               "note" => "some note",
               "text" => "some text"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/highlights", highlight: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update highlight" do
    setup [:create_highlight]

    test "renders highlight when data is valid", %{
      conn: conn,
      highlight: %Highlight{id: id, book_id: book_id} = highlight
    } do
      conn = put(conn, ~p"/api/highlights/#{highlight}", highlight: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/highlights/#{id}")

      assert %{
               "id" => ^id,
               "book_id" => ^book_id,
               "color" => "some updated color",
               "highlight_id" => "some updated highlight_id",
               "last_accessed" => "2026-04-16T11:57:00Z",
               "location" => "some updated location",
               "note" => "some updated note",
               "text" => "some updated text"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, highlight: highlight} do
      conn = put(conn, ~p"/api/highlights/#{highlight}", highlight: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete highlight" do
    setup [:create_highlight]

    test "deletes chosen highlight", %{conn: conn, highlight: highlight} do
      conn = delete(conn, ~p"/api/highlights/#{highlight}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/highlights/#{highlight}")
      end
    end
  end

  defp create_highlight(_) do
    highlight = highlight_fixture()

    %{highlight: highlight}
  end
end
