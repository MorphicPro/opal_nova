defmodule OpalNovaWeb.UserAuthLive do
  import Phoenix.LiveView
  alias OpalNova.Accounts

  def on_mount(_, _, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    socket =
      socket
      |> assign(:current_user, user)
    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end
