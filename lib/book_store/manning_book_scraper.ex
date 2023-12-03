defmodule BookStore.ManningBookScraper do
  def get_all_book_links do
    get_manning_catalog_page()
    |> get_book_links_from_page_source()
    |> Enum.slice(0..1)
    |> Enum.each(&IO.puts/1)
  end

  def get_all_manning_books do
    books_data =
      get_manning_catalog_page()
      |> get_book_links_from_page_source()
      # |> Enum.slice(0..10)
      |> Task.async_stream(&get_book_details/1, max_concurrency: 5, timeout: 10_000)
      |> Enum.reduce([], fn {:ok, book_details}, acc -> [book_details | acc] end)
      |> inspect(pretty: true, limit: :infinity)

    data_file_location()
    |> File.write(books_data)
  end

  def data_file_location, do: "./books_data.exs"

  defp get_manning_catalog_page do
    url = "https://www.manning.com/catalog"
    %HTTPoison.Response{body: body} = HTTPoison.get!(url)

    IO.puts("Got the catalog page")

    body
  end

  defp get_book_links_from_page_source(page_source) do
    page_source
    |> Floki.parse_document!()
    |> Floki.find("a.catalog-link")
    |> Enum.map(fn a_tag ->
      %URI{
        host: "www.manning.com",
        path: a_tag |> Floki.attribute("href"),
        scheme: "https"
      }
      |> URI.to_string()
    end)
  end

  defp get_book_details(book_url) do
    %HTTPoison.Response{body: body} = HTTPoison.get!(book_url)
    parsed_page = Floki.parse_document!(body)

    IO.puts("Got the book page for #{book_url}")

    %{
      title: get_title_from_book_page(parsed_page),
      authors: get_authors_from_book_page(parsed_page),
      description: get_description_from_book_page(parsed_page),
      price: get_price_from_book_page(parsed_page)
    }
  end

  defp get_title_from_book_page(parsed_page) do
    parsed_page
    |> Floki.find("h1.product-title")
    |> Floki.text(deep: false)
    |> String.trim()
  end

  defp get_authors_from_book_page(parsed_page) do
    parsed_page
    |> Floki.find(".product-authors")
    |> Floki.text(deep: false)
    |> String.split([",", "and "])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp get_description_from_book_page(parsed_page) do
    parsed_page
    |> Floki.find(".product-page-section > .product-page-section")
    |> Floki.text(deep: false)
    |> String.trim()
  end

  defp get_price_from_book_page(parsed_page) do
    case parsed_page
         |> Floki.find(".add-to-cart-box ._final-price")
         |> Enum.at(0)
         |> Floki.text(deep: false)
         |> String.trim() do
      "" -> "Not Listed"
      price -> price
    end
  end
end
