defmodule Dailybits.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias Dailybits.Repo

  alias Dailybits.Library.Book

  @doc """
  Returns the list of books.

  ## Examples

      iex> list_books()
      [%Book{}, ...]

  """
  def list_books do
    Repo.all(Book)
  end

  @doc """
  Lists books with highlights preloaded, ordered by title and by highlight `last_accessed` (newest first).
  """
  def list_books_with_highlights do
    from(b in Book,
      order_by: [asc: b.title],
      preload: [
        highlights: ^from(h in Dailybits.Library.Highlight, order_by: [desc: h.last_accessed])
      ]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single book.

  Raises `Ecto.NoResultsError` if the Book does not exist.

  ## Examples

      iex> get_book!(123)
      %Book{}

      iex> get_book!(456)
      ** (Ecto.NoResultsError)

  """
  def get_book!(id), do: Repo.get!(Book, id)

  @doc """
  Loads one book by id with highlights (newest `last_accessed` first), or `:error` if missing.
  """
  def fetch_book_with_highlights(id) do
    query =
      from(b in Book,
        where: b.id == ^id,
        preload: [
          highlights: ^from(h in Dailybits.Library.Highlight, order_by: [desc: h.last_accessed])
        ]
      )

    case Repo.one(query) do
      nil -> :error
      book -> {:ok, book}
    end
  end

  @doc """
  Gets a single book by Amazon ASIN (external id), or `nil` if not found.
  """
  def get_book_by_asin(asin) when is_binary(asin), do: Repo.get_by(Book, asin: asin)

  @doc """
  Creates a book.

  ## Examples

      iex> create_book(%{field: value})
      {:ok, %Book{}}

      iex> create_book(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_book(attrs) do
    %Book{}
    |> Book.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a book.

  ## Examples

      iex> update_book(book, %{field: new_value})
      {:ok, %Book{}}

      iex> update_book(book, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_book(%Book{} = book, attrs) do
    book
    |> Book.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a book.

  ## Examples

      iex> delete_book(book)
      {:ok, %Book{}}

      iex> delete_book(book)
      {:error, %Ecto.Changeset{}}

  """
  def delete_book(%Book{} = book) do
    Repo.delete(book)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking book changes.

  ## Examples

      iex> change_book(book)
      %Ecto.Changeset{data: %Book{}}

  """
  def change_book(%Book{} = book, attrs \\ %{}) do
    Book.changeset(book, attrs)
  end

  alias Dailybits.Library.Highlight

  @doc """
  Returns the list of highlights.

  ## Examples

      iex> list_highlights()
      [%Highlight{}, ...]

  """
  def list_highlights do
    Repo.all(Highlight)
  end

  @doc """
  Gets a single highlight.

  Raises `Ecto.NoResultsError` if the Highlight does not exist.

  ## Examples

      iex> get_highlight!(123)
      %Highlight{}

      iex> get_highlight!(456)
      ** (Ecto.NoResultsError)

  """
  def get_highlight!(id), do: Repo.get!(Highlight, id)

  @doc """
  Creates a highlight.

  ## Examples

      iex> create_highlight(%{field: value})
      {:ok, %Highlight{}}

      iex> create_highlight(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_highlight(attrs) do
    %Highlight{}
    |> Highlight.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Inserts or updates highlights in one statement. Rows must include `:highlight_id` and `:book_id`.

  Empty lists are a no-op. Uses `inserted_at` / `updated_at` from `DateTime.utc_now/0` when omitted.
  """
  def create_highlights_bulk([]), do: {:ok, 0}

  def create_highlights_bulk(attrs) when is_list(attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows =
      Enum.map(attrs, fn row ->
        row
        |> Map.put_new(:inserted_at, now)
        |> Map.put_new(:updated_at, now)
      end)

    {count, _} =
      Repo.insert_all(Highlight, rows,
        on_conflict: :replace_all,
        conflict_target: [:highlight_id]
      )

    {:ok, count}
  end

  @doc """
  Syncs books and highlights from a payload map keyed by ASIN. All-or-nothing in a single transaction.

  Returns `{:ok, %{books: n, highlights: h}}` or `{:error, {:sync, message}}` / `{:error, %Ecto.Changeset{}}`.
  """
  def sync_books_from_books_payload(books) when is_map(books) do
    Repo.transaction(fn ->
      if map_size(books) == 0 do
        Repo.rollback({:sync, "books cannot be empty"})
      else
        case sync_all_books(books) do
          {:ok, stats} -> stats
          {:error, reason} -> Repo.rollback(reason)
        end
      end
    end)
  end

  defp sync_all_books(books) do
    Enum.reduce_while(books, 0, fn {asin, book_data}, acc ->
      case sync_one_book(asin, book_data) do
        {:ok, n} -> {:cont, acc + n}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      total when is_integer(total) -> {:ok, %{books: map_size(books), highlights: total}}
    end
  end

  defp sync_one_book(asin, book_data) do
    with :ok <- validate_asin(asin),
         :ok <- validate_book_payload(book_data),
         {:ok, book_attrs} <- build_book_attrs(book_data),
         {:ok, book} <- upsert_book_by_asin(asin, book_attrs),
         {:ok, hl_list} <- highlights_list(book_data),
         {:ok, highlight_rows} <- build_highlight_rows(book.id, hl_list),
         {:ok, count} <- create_highlights_bulk(highlight_rows) do
      {:ok, count}
    end
  end

  defp validate_asin(asin) do
    case trim_string(asin) do
      nil -> {:error, {:sync, "book key (asin) cannot be empty"}}
      "" -> {:error, {:sync, "book key (asin) cannot be empty"}}
      _ -> :ok
    end
  end

  defp validate_book_payload(data) when is_map(data), do: :ok
  defp validate_book_payload(_), do: {:error, {:sync, "each book must be an object"}}

  defp build_book_attrs(book_data) do
    title = trim_string(book_data["title"])
    author = trim_string(book_data["author"])
    cover = if is_binary(book_data["cover"]), do: book_data["cover"], else: ""

    with :ok <- require_non_blank(title, "title"),
         :ok <- require_non_blank(author, "author"),
         {:ok, last_accessed} <- parse_required_datetime(book_data) do
      {:ok, %{title: title, author: author, cover: cover, last_accessed: last_accessed}}
    end
  end

  defp upsert_book_by_asin(asin, attrs) do
    merged = Map.put(attrs, :asin, asin)

    case get_book_by_asin(asin) do
      nil -> create_book(merged)
      book -> {:ok, book}
    end
  end

  defp highlights_list(book_data) do
    case book_data["highlights"] do
      nil -> {:ok, []}
      list when is_list(list) -> {:ok, list}
      _ -> {:error, {:sync, "highlights must be an array"}}
    end
  end

  defp build_highlight_rows(book_id, highlights) do
    highlights
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {h, idx}, {:ok, acc} ->
      case build_highlight_row(book_id, h) do
        {:ok, row} ->
          {:cont, {:ok, [row | acc]}}

        {:error, {:sync, msg}} ->
          {:halt, {:error, {:sync, "highlight #{idx}: #{msg}"}}}
      end
    end)
    |> case do
      {:ok, rows} -> {:ok, Enum.reverse(rows)}
      {:error, _} = err -> err
    end
  end

  defp build_highlight_row(book_id, data) when is_map(data) do
    id = trim_string(data["id"])
    text = trim_string(data["text"])
    note = normalize_note(data["note"])
    location = trim_string(data["location"])
    color = trim_string(data["color"])

    with :ok <- require_non_blank(id, "id"),
         :ok <- require_non_blank(text, "text"),
         :ok <- require_non_blank(location, "location"),
         :ok <- require_non_blank(color, "color"),
         {:ok, last_accessed} <- parse_required_datetime(data) do
      {:ok,
       %{
         book_id: book_id,
         highlight_id: id,
         text: text,
         note: note,
         location: location,
         color: color,
         last_accessed: last_accessed
       }}
    end
  end

  defp build_highlight_row(_book_id, _data) do
    {:error, {:sync, "each highlight must be an object"}}
  end

  defp normalize_note(note) when is_binary(note), do: note
  defp normalize_note(nil), do: ""
  defp normalize_note(_), do: ""

  defp require_non_blank(s, label) when is_binary(s) do
    if String.trim(s) == "" do
      {:error, {:sync, "#{label} cannot be empty"}}
    else
      :ok
    end
  end

  defp require_non_blank(_s, label), do: {:error, {:sync, "#{label} cannot be empty"}}

  defp trim_string(nil), do: nil
  defp trim_string(s) when is_binary(s), do: String.trim(s)
  defp trim_string(_), do: nil

  defp parse_required_datetime(map) do
    case parse_iso_datetime(map) do
      nil -> {:error, {:sync, "last_accessed is missing or invalid"}}
      dt -> {:ok, dt}
    end
  end

  defp parse_iso_datetime(map) when is_map(map) do
    raw = map["lastAccessed"] || map["last_accessed"]

    case raw do
      nil ->
        nil

      s when is_binary(s) ->
        case DateTime.from_iso8601(s) do
          {:ok, dt, _offset} -> DateTime.truncate(dt, :second)
          {:error, _} -> nil
        end

      _ ->
        nil
    end
  end

  @doc """
  Updates a highlight.

  ## Examples

      iex> update_highlight(highlight, %{field: new_value})
      {:ok, %Highlight{}}

      iex> update_highlight(highlight, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_highlight(%Highlight{} = highlight, attrs) do
    highlight
    |> Highlight.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a highlight.

  ## Examples

      iex> delete_highlight(highlight)
      {:ok, %Highlight{}}

      iex> delete_highlight(highlight)
      {:error, %Ecto.Changeset{}}

  """
  def delete_highlight(%Highlight{} = highlight) do
    Repo.delete(highlight)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking highlight changes.

  ## Examples

      iex> change_highlight(highlight)
      %Ecto.Changeset{data: %Highlight{}}

  """
  def change_highlight(%Highlight{} = highlight, attrs \\ %{}) do
    Highlight.changeset(highlight, attrs)
  end
end
