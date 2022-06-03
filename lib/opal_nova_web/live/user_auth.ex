defmodule OpalNovaWeb.UserAuthLive do
  import Phoenix.LiveView
  alias OpalNova.Accounts

  def on_mount(_, _, %{"user_token" => user_token}, socket) do
    user = %{admin: admin} = Accounts.get_user_by_session_token(user_token)

    socket =
      socket
      |> assign(:current_user, user)

    if socket.assigns.current_user do
      if admin do
        {:cont, socket}
      else
        {:halt, socket |> put_flash(:error, "Not Authorized") |> redirect(to: "/")}
      end
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end
