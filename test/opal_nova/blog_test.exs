defmodule OpalNova.BlogTest do
  use OpalNova.DataCase

  alias OpalNova.Blog

  describe "posts" do
    alias OpalNova.Blog.Post

    import OpalNova.BlogFixtures

    @invalid_attrs %{body: nil, description: nil, draft: nil, published_at: nil, title: nil}

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Blog.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Blog.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post" do
      valid_attrs = %{
        body: "some body",
        description: "some description",
        draft: true,
        published_at: ~D[2022-04-20],
        title: "some title"
      }

      assert {:ok, %Post{} = post} = Blog.create_post(valid_attrs)
      assert post.body == "some body"
      assert post.description == "some description"
      assert post.draft == true
      assert post.published_at == ~D[2022-04-20]
      assert post.title == "some title"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Blog.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()

      update_attrs = %{
        body: "some updated body",
        description: "some updated description",
        draft: false,
        published_at: ~D[2022-04-21],
        title: "some updated title"
      }

      assert {:ok, %Post{} = post} = Blog.update_post(post, update_attrs)
      assert post.body == "some updated body"
      assert post.description == "some updated description"
      assert post.draft == false
      assert post.published_at == ~D[2022-04-21]
      assert post.title == "some updated title"
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Blog.update_post(post, @invalid_attrs)
      assert post == Blog.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Blog.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Blog.change_post(post)
    end
  end
end
