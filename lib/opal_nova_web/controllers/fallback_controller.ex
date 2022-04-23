defmodule OpalNovaWeb.FallbackController do
  use OpalNovaWeb, :controller

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> put_view(OpalNovaWeb.ErrorView)
    |> render(:"403")
  end
end
