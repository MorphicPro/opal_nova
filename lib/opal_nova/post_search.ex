defmodule OpalNova.PostSearch do
  import Ecto.Query

  def run(query, search_string) do
    _run(query, normalize(search_string))
  end

  defmacro matching_post_ids_and_ranks(search_string) do
    quote do
      fragment(
        """
        SELECT post_search_v2.id AS id,
        ts_rank(
          post_search_v2.document, plainto_tsquery(unaccent(?))
        ) AS rank
        FROM post_search_v2
        WHERE post_search_v2.document @@ plainto_tsquery(unaccent(?))
        OR post_search_v2.title ILIKE ?
        """,
        ^unquote(search_string),
        ^unquote(search_string),
        ^"%#{unquote(search_string)}%"
      )
    end
  end

  defp _run(query, ""), do: query

  defp _run(query, search_string) do
    from post in query,
      join: id_and_rank in matching_post_ids_and_ranks(search_string),
      on: id_and_rank.id == post.id,
      order_by: [desc: id_and_rank.rank]
  end

  defp normalize(search_string) do
    search_string
    |> String.downcase()
    |> String.replace("gluten free", "gluten-free")
    |> String.replace("dairy free", "dairy-free")
    |> String.replace("sugar free", "sugar-free")
    |> String.replace("meatless", "no-meat")
    |> String.replace("vegetarian", "no-meat")
    |> String.replace(~r/\n/, " ")
    |> String.replace(~r/\t/, " ")
    |> String.replace(~r/\s{2,}/, " ")
    |> String.trim()
  end
end
