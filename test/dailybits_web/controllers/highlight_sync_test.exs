defmodule DailybitsWeb.HighlightSyncTest do
  use DailybitsWeb.ConnCase

  @sync_path "/api/highlights/sync"

  @payload %{
    "status" => "success",
    "userName" => "test@example.com",
    "books" => %{
      "B0SYNCBOOK001" => %{
        "id" => "B0SYNCBOOK001",
        "title" => "Sync Test Book",
        "author" => "Sync Author",
        "cover" => "https://example.com/cover.jpg",
        "lastAccessed" => "2026-04-16T12:00:00Z",
        "highlights" => []
      }
    }
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "POST #{@sync_path} accepts books payload and returns success", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(@sync_path, Jason.encode!(@payload))

    assert %{"status" => "success", "data" => %{"books" => 1, "highlights" => 0}} =
             json_response(conn, 200)
  end

  test "POST #{@sync_path} rejects empty books map", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(@sync_path, Jason.encode!(%{"books" => %{}}))

    assert %{"error" => "books cannot be empty"} = json_response(conn, 422)
  end

  test "POST #{@sync_path} with example_sync.json fixture", %{conn: conn} do
    path = Path.expand("../../support/example_sync.json", __DIR__)
    body = File.read!(path)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(@sync_path, body)

    assert %{"status" => "success", "data" => %{"books" => 2, "highlights" => 3}} =
             json_response(conn, 200)
  end
end
