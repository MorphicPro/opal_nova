defmodule OpalNova.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :body, :string
    field :description, :string
    field :draft, :boolean, default: false
    field :published_at, :date
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :description, :published_at, :draft])
    |> validate_required([:title, :body, :description, :published_at, :draft])
  end
end
