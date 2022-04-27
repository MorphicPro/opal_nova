defmodule OpalNovaWeb.Admin.PostLive.Index do
  use OpalNovaWeb, :live_view_admin

  alias OpalNova.Blog

  @impl true
  def mount(_params, _session, socket) do
    posts = list_posts()

    if connected?(socket) do
      Enum.each(posts, fn %{id: id} ->
        Phoenix.PubSub.subscribe(OpalNova.PubSub, "post:#{id}")
      end)
    end

    {:ok, assign(socket, :posts, list_posts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Blog.get_post!(id)
    {:ok, _} = Blog.delete_post(post)

    {:noreply, assign(socket, :posts, list_posts())}
  end

  def handle_event("search", %{"_target" => ["search"], "search" => search}, socket) do
    {:noreply, assign(socket, :posts, OpalNova.Blog.post_search(search))}
  end

  def handle_event("save", %{"search" => search}, socket) do
    {:noreply, assign(socket, :posts, OpalNova.Blog.post_search(search))}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, assign(socket, :posts, OpalNova.Blog.post_search(search))}
  end

  @impl true
  def handle_info({:post_edited, %{id: id} = post}, %{assigns: %{posts: posts}} = socket) do
    posts =
      Enum.map(posts, fn
        %{id: ^id} -> post
        p -> p
      end)

    {:noreply, assign(socket, posts: posts)}
  end

  defp list_posts do
    Blog.list_posts()
  end
end
