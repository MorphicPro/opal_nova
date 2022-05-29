defmodule OpalNova.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpalNova.Blog.{Tag, Tagging}

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
    field :tag_list, {:array, :string}, virtual: true
    field :comment_count, :integer, default: 0

    many_to_many(:tags, Tag,
      join_through: "post_tags",
      on_delete: :delete_all,
      on_replace: :delete
    )

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
      :thumb_image,
      :comment_count,
    ])
    |> validate_required([
      :title,
      :body,
      :description,
      :published_at,
      :draft,
      :cover_image,
      :slug,
    ])
    |> put_tags_list()
    |> parse_tags_assoc()
  end

  defp put_tags_list(%{valid?: true, changes: %{description: description}} = changeset) do
    tag_list = Regex.scan(~r/(#\w+)/, description) |> Enum.map(fn [_, tag] -> tag |> String.replace("#", "") end)

    changeset
    |> put_change(:tag_list, tag_list)
  end

  defp put_tags_list(changeset), do: changeset

  defp parse_tags_assoc(
         %Ecto.Changeset{valid?: true, changes: %{tag_list: _tags_list}} = changeset
       ) do
    changeset
    |> Tagging.changeset(OpalNova.Blog.Tag, :tags, :tag_list)
  end

  defp parse_tags_assoc(changeset), do: changeset
end
