defmodule OpalNova.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false

  alias OpalNova.Repo
  alias OpalNova.Blog.{Post, Tag}
  alias OpalNova.Accounts.User

  @behaviour Bodyguard.Policy

  # Admin users can do anything
  @spec authorize(any, any, any) :: boolean
  def authorize(_, %User{admin: true}, _), do: true

  # Regular users can create posts
  def authorize(:list_posts, _, _), do: true
  def authorize(:get_post!, _, _), do: true

  # Catch-all: deny everything else
  def authorize(_, _, _), do: false

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts(params, user) do
    from(
      p in Post,
      preload: [:tags]
    )
    |> Bodyguard.scope(user)
    |> Repo.order_by_published_at()
    |> Dissolver.paginate(params)
  end

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    from(p in Post, order_by: [desc: p.published_at])
    |> Repo.all()
  end

  def list_published_posts do
    Post
    |> Repo.where_published()
    |> Repo.order_by_published_at()
    |> Repo.all()
  end

  def post_search(search) do
    from(p in Post, order_by: [desc: p.inserted_at])
    |> OpalNova.PostSearch.run(search)
    |> Repo.all()
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id), do: Repo.get!(Post, id)


  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!("foo")
      %Post{}

      iex> get_post!("bar")
      ** (Ecto.NoResultsError)

  """
  def get_post!(id, current_user, options \\ []) do
    preload = Keyword.get(options, :preload, [])

    Post
    |> Repo.by_id(id)
    |> from(preload: ^preload)
    |> Bodyguard.scope(current_user)
    |> Repo.one!()
  end


  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post_by_slug!(slug, _, options \\ []) do
    preload = Keyword.get(options, :preload, [])

    Post
    |> Repo.by_slug(slug)
    |> Repo.where_published()
    |> from(preload: ^preload)
    # |> Bodyguard.scope(current_user)
    |> Repo.one!()
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(%{field: value})
      {:ok, %Post{}}

      iex> create_post(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  alias OpalNova.Blog.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}, captcha_text) do
    %Comment{}
    |> Comment.changeset(attrs, captcha_text)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs, captcha_text) do
    comment
    |> Comment.changeset(attrs, captcha_text)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

   @doc """
  Gets a single tag and all of its pics.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag_by_slug!(foobar)
      %Tag{ pics: [...] }

      iex> get_comment!(badtag)
      ** (Ecto.NoResultsError)

  """
  def get_post_for_tag!(tag_name, user, params \\ %{}) do
    posts =
      from(p in Post)
      |> Bodyguard.scope(user)

    [total_count] =
      from(pt in "post_tags",
        join: p in ^posts,
        on: p.id == pt.post_id,
        join: t in "tags",
        on: t.id == pt.tag_id,
        where: t.name == ^tag_name,
        select: count()
      )
      |> Repo.all()

    {posts_query, k} =
      from(p in Post, order_by: [desc: :inserted_at], preload: [:tags])
      |> Bodyguard.scope(user)
      |> Dissolver.paginate(params, total_count: total_count, lazy: true)

    tag =
      from(t in Tag, where: t.name == ^tag_name, preload: [posts: ^posts_query])
      |> Repo.one!()

    {tag, k}
  end
end
