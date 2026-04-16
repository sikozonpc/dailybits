defmodule Dailybits.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dailybits.Library` context.
  """

  @doc """
  Generate a unique book asin.
  """
  def unique_book_asin, do: "some asin#{System.unique_integer([:positive])}"

  @doc """
  Generate a book.
  """
  def book_fixture(attrs \\ %{}) do
    {:ok, book} =
      attrs
      |> Enum.into(%{
        asin: unique_book_asin(),
        author: "some author",
        cover: "some cover",
        last_accessed: ~U[2026-04-15 11:57:00Z],
        title: "some title"
      })
      |> Dailybits.Library.create_book()

    book
  end

  @doc """
  Generate a unique highlight highlight_id.
  """
  def unique_highlight_highlight_id, do: "some highlight_id#{System.unique_integer([:positive])}"

  @doc """
  Generate a highlight.
  """
  def highlight_fixture(attrs \\ %{}) do
    defaults = %{
      color: "some color",
      highlight_id: unique_highlight_highlight_id(),
      last_accessed: ~U[2026-04-15 11:57:00Z],
      location: "some location",
      note: "some note",
      text: "some text"
    }

    merged = Map.merge(defaults, attrs)

    merged =
      if Map.has_key?(merged, :book_id) do
        merged
      else
        Map.put(merged, :book_id, book_fixture().id)
      end

    {:ok, highlight} = Dailybits.Library.create_highlight(merged)

    highlight
  end
end
