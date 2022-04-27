defmodule OpalNovaWeb.PostLive.Show do
  use OpalNovaWeb, :live_view

  alias OpalNova.Blog
  alias OpalNova.Blog.Comment

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    if connected?(socket) do
      %{id: id} = Blog.get_post_by_slug!(slug, %{})
      Phoenix.PubSub.subscribe(OpalNova.PubSub, "post:#{id}")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
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
end
