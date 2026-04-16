defmodule DailybitsWeb.BookJSON do
  alias Dailybits.Library.Book

  @doc """
  Renders a list of books.
  """
  def index(%{books: books}) do
    %{data: for(book <- books, do: data(book))}
  end

  @doc """
  Renders a single book.
  """
  def show(%{book: book}) do
    %{data: data(book)}
  end

  defp data(%Book{} = book) do
    %{
      id: book.id,
      asin: book.asin,
      title: book.title,
      author: book.author,
      cover: book.cover,
      last_accessed: book.last_accessed
    }
  end
end
