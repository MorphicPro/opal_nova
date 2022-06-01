defmodule OpalNovaWeb.PostLive.Show do
  use OpalNovaWeb, :live_view

  alias OpalNova.Blog.Comment
  alias OpalNova.{Blog, Presence, PubSub}

  @presence "opal_nova:presence"

  @impl true
  def mount(%{"slug" => slug}, _session, %{assigns: %{current_user: nil}} = socket) do
    post = Blog.get_post_by_slug!(slug, %{}, preload: [:comments])

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @presence, Enum.random(0..1000), %{
          name: "anonymous #{Enum.random(0..1000)}",
          joined_at: :os.system_time(:seconds)
        })

      Phoenix.PubSub.subscribe(PubSub, @presence)
      Phoenix.PubSub.subscribe(PubSub, "post:#{post.id}")
    end

    {:ok,
     socket
     |> assign(:page_title, post.title)
     |> assign(:post, post)
     |> assign(:users, %{})
     |> handle_joins(Presence.list(@presence))}
  end

  def mount(%{"slug" => slug}, _session, %{assigns: %{current_user: current_user}} = socket) do
    post = Blog.get_post_by_slug!(slug, current_user, preload: [:comments])

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @presence, current_user.id, %{
          name: current_user.email,
          joined_at: :os.system_time(:seconds)
        })

      Phoenix.PubSub.subscribe(PubSub, @presence)
      Phoenix.PubSub.subscribe(PubSub, "post:#{post.id}")
    end

    {:ok,
     socket
     |> assign(:page_title, post.title)
     |> assign(:post, post)
     |> assign(:users, %{})
     |> handle_joins(Presence.list(@presence))}
  end

  def mount(%{"slug" => slug}, _session, socket) do
    if connected?(socket) do
      %{id: id} = Blog.get_post_by_slug!(slug, %{})
      Phoenix.PubSub.subscribe(OpalNova.PubSub, "post:#{id}")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _session, socket) do
    post = Blog.get_post_by_slug!(slug, %{}, preload: [:comments])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:comment, %Comment{})}
  end

  @impl true
  def handle_info({:post_edited, post}, socket) do
    {:noreply, assign(socket, post: post)}
  end

  # def handle_info({:new_comment, comment}, %{assigns: %{post: post}} = socket) do
  #  {:noreply, assign(socket, post: post |> Map.merge(%{comments: post.comments ++ [comment]}))}

  def handle_info({:new_comment, comment}, %{assigns: %{post: post}} = socket) do
    {:noreply, assign(socket, post: post |> Map.merge(%{comments: post.comments ++ [comment]}))}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  defp page_title(:show), do: "Show Post"

  def comments(assigns) do
    ~H"""
    <%= for comment <- @comments do %>
    <div class="mb-8">
      <div class="flex space-x-3 prose mx-auto">
        <div>
          <div class="text-sm">
            <span class="font-medium text-gray-900"><%= comment.name %></span>
          </div>
          <div class="mt-1 text-sm text-gray-700">
            <%= comment.message %>
          </div>
          <div class="mt-2 text-sm space-x-2">
            <span class="text-gray-500 font-medium"><%= Timex.from_now(comment.inserted_at) %></span>
          </div>
        </div>
      </div>
    </div>
    <% end %>
    """
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
