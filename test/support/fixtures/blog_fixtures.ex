defmodule OpalNova.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpalNova.Blog` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        body: "some body",
        description: "some description",
        draft: true,
        published_at: ~D[2022-04-20],
        title: "some title"
      })
      |> OpalNova.Blog.create_post()

    post
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        flagged: true,
        message: "some message"
      })
      |> OpalNova.Blog.create_comment()

    comment
  end
end
