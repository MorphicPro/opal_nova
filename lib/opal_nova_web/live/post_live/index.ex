defmodule OpalNovaWeb.PostLive.Index do
  use OpalNovaWeb, :live_view

  import OpalNovaWeb.Dissolver.Live.Tailwind

  alias OpalNova.{Blog, Presence, PubSub}

  @presence "opal_nova:presence"

  @impl true
  def mount(params, _session, %{assigns: %{current_user: nil}} = socket) do
    {posts, dissolver} = Blog.list_posts(params, nil)

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @presence, Enum.random(0..1000), %{
          name: "anonymous #{Enum.random(0..1000)}",
          joined_at: :os.system_time(:seconds)
        })

      Phoenix.PubSub.subscribe(PubSub, @presence)

      Enum.each(posts, fn %{id: id} ->
        Phoenix.PubSub.subscribe(PubSub, "post:#{id}")
      end)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Posts")
     |> assign(:post, nil)
     |> assign(:posts, posts)
     |> assign(:dissolver, dissolver)
     |> assign(scope: nil)
     |> assign(:users, %{})
     |> handle_joins(Presence.list(@presence))}
  end

  def mount(params, _session, %{assigns: %{current_user: current_user}} = socket) do
    {posts, dissolver} = Blog.list_posts(params, current_user)

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @presence, current_user.id, %{
          name: current_user.email,
          joined_at: :os.system_time(:seconds)
        })

      Phoenix.PubSub.subscribe(PubSub, @presence)

      Enum.each(posts, fn %{id: id} ->
        Phoenix.PubSub.subscribe(PubSub, "post:#{id}")
      end)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Posts")
     |> assign(:post, nil)
     |> assign(:posts, posts)
     |> assign(:dissolver, dissolver)
     |> assign(scope: nil)
     |> assign(:users, %{})
     |> handle_joins(Presence.list(@presence))}
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

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  defp list_posts do
    Blog.list_published_posts()
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      assign(socket, :users, Map.put(socket.assigns.users, user, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users, Map.delete(socket.assigns.users, user))
    end)
  end
end
