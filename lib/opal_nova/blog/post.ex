defmodule OpalNova.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Bodyguard.Schema

  def scope(query, %OpalNova.Accounts.User{admin: true}, _) do
    query
  end

  def scope(query, _, _) do
    query
    |> OpalNova.Repo.where_published()
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :body, :string
    field :description, :string
    field :draft, :boolean, default: true
    field :published_at, :date
    field :title, :string
    field :slug, :string
    field :source_image, :string
    field :cover_image, :string
    field :thumb_image, :string

    has_many :comments, OpalNova.Blog.Comment

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :title,
      :slug,
      :body,
      :description,
      :published_at,
      :draft,
      :cover_image,
      :source_image,
      :cover_image,
      :thumb_image
    ])
    |> validate_required([:title, :body, :description, :published_at, :draft, :cover_image, :slug])
  end
end
