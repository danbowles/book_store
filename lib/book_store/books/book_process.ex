defmodule BookStore.Books.BookProcess do
  use GenServer, restart: :transient

  require Logger
  alias BookStore.Repo
  alias BookStore.Books.Book
  alias Ecto.Changeset

  def start_link(%Book{} = book) do
    GenServer.start_link(
      __MODULE__,
      book,
      name: {:via, Registry, {BookStore.BookRegistry, book.id}}
    )
  end

  @impl true
  def init(%Book{} = state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:read, _from, %Book{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:update, attrs}, _from, %Book{} = state) do
    state
    |> update_book(attrs)
    |> case do
      {:ok, book} ->
        {:reply, book, book, {:continue, :perist_book_changes}}

      error ->
        {:reply, error, state}
    end

    changeset = Book.changeset(state, attrs)

    case Repo.update(changeset) do
      {:ok, book} ->
        {:reply, book, book}

      {:error, changeset} ->
        {:reply, changeset, state}
    end
  end
end
