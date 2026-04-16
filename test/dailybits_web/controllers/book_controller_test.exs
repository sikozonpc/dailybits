defmodule DailybitsWeb.BookControllerTest do
  use DailybitsWeb.ConnCase

  import Dailybits.LibraryFixtures
  alias Dailybits.Library.Book

  @create_attrs %{
    asin: "some asin",
    title: "some title",
    author: "some author",
    cover: "some cover",
    last_accessed: ~U[2026-04-15 11:57:00Z]
  }
  @update_attrs %{
    asin: "some updated asin",
    title: "some updated title",
    author: "some updated author",
    cover: "some updated cover",
    last_accessed: ~U[2026-04-16 11:57:00Z]
  }
  @invalid_attrs %{asin: nil, title: nil, author: nil, cover: nil, last_accessed: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all books", %{conn: conn} do
      conn = get(conn, ~p"/api/books")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create book" do
    test "renders book when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/books", book: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/books/#{id}")

      assert %{
               "id" => ^id,
               "asin" => "some asin",
               "author" => "some author",
               "cover" => "some cover",
               "last_accessed" => "2026-04-15T11:57:00Z",
               "title" => "some title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/books", book: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update book" do
    setup [:create_book]

    test "renders book when data is valid", %{conn: conn, book: %Book{id: id} = book} do
      conn = put(conn, ~p"/api/books/#{book}", book: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/books/#{id}")

      assert %{
               "id" => ^id,
               "asin" => "some updated asin",
               "author" => "some updated author",
               "cover" => "some updated cover",
               "last_accessed" => "2026-04-16T11:57:00Z",
               "title" => "some updated title"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, book: book} do
      conn = put(conn, ~p"/api/books/#{book}", book: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete book" do
    setup [:create_book]

    test "deletes chosen book", %{conn: conn, book: book} do
      conn = delete(conn, ~p"/api/books/#{book}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/books/#{book}")
      end
    end
  end

  defp create_book(_) do
    book = book_fixture()

    %{book: book}
  end
end
