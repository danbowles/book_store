# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     BookStore.Repo.insert!(%BookStore.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias BookStore.Books.Book
alias BookStore.Repo

{book_data, _} =
  BookStore.ManningBookScraper.data_file_location()
  |> Code.eval_file()

book_data
|> Enum.map(fn
  %{price: "Not Listed"} = book ->
    book
    |> Map.put(:price, "N/A")
    |> Map.put(:quantity, 0)

  book ->
    book |> Map.put(:quantity, 5_000)
end)
|> Enum.map(fn
  %{description: ""} = book ->
    book
    |> Map.put(:description, "No description available")

  book ->
    book
end)
|> Enum.each(fn book ->
  Book.changeset(%Book{}, book)
  |> Repo.insert!()
end)
