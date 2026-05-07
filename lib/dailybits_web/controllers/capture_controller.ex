defmodule DailybitsWeb.CaptureController do
  use DailybitsWeb, :controller

  alias Dailybits.Library

  def web(conn, attrs) do
    case Dailybits.Library.upsert_object(attrs) do
      {:ok, _object} ->
        send_resp(conn, 200, "ok")

      {:error, changeset} ->
        IO.inspect(changeset, label: "Failed to upsert object")
        send_resp(conn, 500, "error")
    end
  end

  def sync(conn, %{"books" => books}) do
    case Library.sync_books_from_books_payload(books) do
      {:ok, stats} ->
        json(conn, %{status: "success", data: stats})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}

      {:error, {:sync, message}} when is_binary(message) ->
        {:error, {:sync, message}}
    end
  end

  def sync(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "expected a \"books\" object"})
  end
end
