defmodule OpalNovaWeb.PostLive.Index do
  use OpalNovaWeb, :live_view

  alias OpalNova.Blog

  import OpalNovaWeb.Dissolver.Live.Tailwind

  @impl true
  def mount(params, _session, socket) do
    {posts, dissolver} = Blog.list_posts(params, socket.assigns.current_user)

    if connected?(socket) do
      Enum.each(posts, fn %{id: id} ->
        Phoenix.PubSub.subscribe(OpalNova.PubSub, "post:#{id}")
      end)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Posts")
     |> assign(:post, nil)
     |> assign(:posts, posts)
     |> assign(:dissolver, dissolver)
     |> assign(scope: nil)}
  end

  def mount(%{tag: tag} = params, _session, socket) do
    {tag, dissolver} = Blog.get_post_for_tag!(tag, socket.assigns.current_user, params)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(OpalNova.PubSub, "post:tag:#{tag}")
      Enum.each(tag.posts, fn %{id: id} ->
        Phoenix.PubSub.subscribe(OpalNova.PubSub, "post:#{id}")
      end)
    end

    {:ok,
     socket
     |> assign(page_title: "Listing Posts")
     |> assign(scope: tag.name)
     |> assign(posts: tag.posts)
     |> assign(:dissolver, dissolver)
     |> assign(:post, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :index, params) do
    {posts, dissolver} = Blog.list_posts(params, current_user)

    socket
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
    |> assign(:posts, posts)
    |> assign(:dissolver, dissolver)
    |> assign(scope: nil)
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :tag,
         %{"tag" => tag} = params
       ) do
    {tag, dissolver} = Blog.get_post_for_tag!(tag, current_user, params)

    socket
    |> assign(page_title: "Listing Posts")
    |> assign(scope: tag.name)
    |> assign(posts: tag.posts)
    |> assign(:dissolver, dissolver)
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
    Blog.list_published_posts()
  end
end
