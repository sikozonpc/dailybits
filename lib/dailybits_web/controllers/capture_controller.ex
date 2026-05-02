defmodule DailybitsWeb.CaptureController do
  use DailybitsWeb, :controller

  def web(conn, attrs) do
    case Dailybits.Library.upsert_object(attrs) do
      {:ok, _object} ->
        send_resp(conn, 200, "ok")

      {:error, changeset} ->
        IO.inspect(changeset, label: "Failed to upsert object")
        send_resp(conn, 500, "error")
    end
  end

  def sync(conn, %{"content" => content}) do
    IO.inspect(content, label: "Captured content")
    send_resp(conn, 200, "ok")
  end
end
