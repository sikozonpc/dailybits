defmodule DailybitsWeb.HighlightController do
  use DailybitsWeb, :controller

  alias Dailybits.Library
  alias Dailybits.Library.Highlight

  action_fallback DailybitsWeb.FallbackController

  def daily(conn, _params) do
    highlights = Library.get_random_highlights()
    render(conn, :daily, highlights: highlights)
  end

  def sync(conn, %{"books" => books}) when is_map(books) do
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

  def index(conn, _params) do
    highlights = Library.list_highlights()
    render(conn, :index, highlights: highlights)
  end

  def create(conn, %{"highlight" => highlight_params}) do
    with {:ok, %Highlight{} = highlight} <- Library.create_highlight(highlight_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/highlights/#{highlight}")
      |> render(:show, highlight: highlight)
    end
  end

  def show(conn, %{"id" => id}) do
    highlight = Library.get_highlight!(id)
    render(conn, :show, highlight: highlight)
  end

  def update(conn, %{"id" => id, "highlight" => highlight_params}) do
    highlight = Library.get_highlight!(id)

    with {:ok, %Highlight{} = highlight} <- Library.update_highlight(highlight, highlight_params) do
      render(conn, :show, highlight: highlight)
    end
  end

  def delete(conn, %{"id" => id}) do
    highlight = Library.get_highlight!(id)

    with {:ok, %Highlight{}} <- Library.delete_highlight(highlight) do
      send_resp(conn, :no_content, "")
    end
  end
end
