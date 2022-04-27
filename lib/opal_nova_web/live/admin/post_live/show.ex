defmodule OpalNovaWeb.Admin.PostLive.Show do
  use OpalNovaWeb, :live_view_admin

  alias OpalNova.Blog

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(OpalNova.PubSub, "post:#{id}")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Blog.get_post!(id))}
  end

  @impl true
  def handle_info({:post_edited, post}, socket) do
    {:noreply, assign(socket, post: post)}
  end

  defp page_title(:show), do: "Show Post"
end
