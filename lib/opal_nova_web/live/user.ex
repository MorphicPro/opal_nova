defmodule OpalNovaWeb.UserLive do
  import Phoenix.LiveView
  alias OpalNova.Accounts

  def on_mount(_, _, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    socket =
      socket
      |> assign(:current_user, user)

    {:cont, socket}
  end

  def on_mount(_, _, %{}, socket) do
    {:cont, socket |> assign(:current_user, nil)}
  end
end
