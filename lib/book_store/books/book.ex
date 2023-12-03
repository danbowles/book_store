defmodule BookStore.Books.Book do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @derive {Jason.Encoder, only: [:id, :title, :authors, :description, :price, :quantity]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "books" do
    field :title, :string
    field :authors, {:array, :string}
    field :description, :string
    field :price, :string
    field :quantity, :integer
    timestamps()
  end

  @doc false
  def changeset(%Book{} = book, attrs) do
    book
    |> cast(attrs, [:title, :authors, :description, :price, :quantity])
    |> validate_required([:title, :authors, :description, :quantity])
  end
end
