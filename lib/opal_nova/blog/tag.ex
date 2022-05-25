defmodule OpalNova.Blog.Tag do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tags" do
    field(:name)
    many_to_many(:posts, OpalNova.Blog.Post, join_through: "post_tags")
  end
end
