defmodule Dailybits.LibraryTest do
  use Dailybits.DataCase

  alias Dailybits.Library

  describe "books" do
    alias Dailybits.Library.Book

    import Dailybits.LibraryFixtures

    @invalid_attrs %{asin: nil, title: nil, author: nil, cover: nil, last_accessed: nil}

    test "list_books/0 returns all books" do
      book = book_fixture()
      assert Library.list_books() == [book]
    end

    test "get_book!/1 returns the book with given id" do
      book = book_fixture()
      assert Library.get_book!(book.id) == book
    end

    test "create_book/1 with valid data creates a book" do
      valid_attrs = %{
        asin: "some asin",
        title: "some title",
        author: "some author",
        cover: "some cover",
        last_accessed: ~U[2026-04-15 11:57:00Z]
      }

      assert {:ok, %Book{} = book} = Library.create_book(valid_attrs)
      assert book.asin == "some asin"
      assert book.title == "some title"
      assert book.author == "some author"
      assert book.cover == "some cover"
      assert book.last_accessed == ~U[2026-04-15 11:57:00Z]
    end

    test "create_book/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_book(@invalid_attrs)
    end

    test "update_book/2 with valid data updates the book" do
      book = book_fixture()

      update_attrs = %{
        asin: "some updated asin",
        title: "some updated title",
        author: "some updated author",
        cover: "some updated cover",
        last_accessed: ~U[2026-04-16 11:57:00Z]
      }

      assert {:ok, %Book{} = book} = Library.update_book(book, update_attrs)
      assert book.asin == "some updated asin"
      assert book.title == "some updated title"
      assert book.author == "some updated author"
      assert book.cover == "some updated cover"
      assert book.last_accessed == ~U[2026-04-16 11:57:00Z]
    end

    test "update_book/2 with invalid data returns error changeset" do
      book = book_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_book(book, @invalid_attrs)
      assert book == Library.get_book!(book.id)
    end

    test "delete_book/1 deletes the book" do
      book = book_fixture()
      assert {:ok, %Book{}} = Library.delete_book(book)
      assert_raise Ecto.NoResultsError, fn -> Library.get_book!(book.id) end
    end

    test "change_book/1 returns a book changeset" do
      book = book_fixture()
      assert %Ecto.Changeset{} = Library.change_book(book)
    end
  end

  describe "highlights" do
    alias Dailybits.Library.Highlight

    import Dailybits.LibraryFixtures

    @invalid_attrs %{
      book_id: nil,
      location: nil,
      text: nil,
      color: nil,
      highlight_id: nil,
      note: nil,
      last_accessed: nil
    }

    test "list_highlights/0 returns all highlights" do
      highlight = highlight_fixture()
      assert Library.list_highlights() == [highlight]
    end

    test "get_highlight!/1 returns the highlight with given id" do
      highlight = highlight_fixture()
      assert Library.get_highlight!(highlight.id) == highlight
    end

    test "create_highlight/1 with valid data creates a highlight" do
      book = book_fixture()

      valid_attrs = %{
        book_id: book.id,
        location: "some location",
        text: "some text",
        color: "some color",
        highlight_id: "some highlight_id",
        note: "some note",
        last_accessed: ~U[2026-04-15 11:57:00Z]
      }

      assert {:ok, %Highlight{} = highlight} = Library.create_highlight(valid_attrs)
      assert highlight.location == "some location"
      assert highlight.text == "some text"
      assert highlight.color == "some color"
      assert highlight.highlight_id == "some highlight_id"
      assert highlight.note == "some note"
      assert highlight.book_id == book.id
      assert highlight.last_accessed == ~U[2026-04-15 11:57:00Z]
    end

    test "create_highlight/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_highlight(@invalid_attrs)
    end

    test "update_highlight/2 with valid data updates the highlight" do
      highlight = highlight_fixture()

      update_attrs = %{
        location: "some updated location",
        text: "some updated text",
        color: "some updated color",
        highlight_id: "some updated highlight_id",
        note: "some updated note",
        last_accessed: ~U[2026-04-16 11:57:00Z]
      }

      assert {:ok, %Highlight{} = highlight} = Library.update_highlight(highlight, update_attrs)
      assert highlight.location == "some updated location"
      assert highlight.text == "some updated text"
      assert highlight.color == "some updated color"
      assert highlight.highlight_id == "some updated highlight_id"
      assert highlight.note == "some updated note"
      assert highlight.last_accessed == ~U[2026-04-16 11:57:00Z]
    end

    test "update_highlight/2 with invalid data returns error changeset" do
      highlight = highlight_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_highlight(highlight, @invalid_attrs)
      assert highlight == Library.get_highlight!(highlight.id)
    end

    test "delete_highlight/1 deletes the highlight" do
      highlight = highlight_fixture()
      assert {:ok, %Highlight{}} = Library.delete_highlight(highlight)
      assert_raise Ecto.NoResultsError, fn -> Library.get_highlight!(highlight.id) end
    end

    test "change_highlight/1 returns a highlight changeset" do
      highlight = highlight_fixture()
      assert %Ecto.Changeset{} = Library.change_highlight(highlight)
    end
  end
end
