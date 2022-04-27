defmodule OpalNovaWeb.Plug.Log do
  import Plug.Conn

  def inspect_conn(conn, _opts) do
    case get_req_header(conn, "referer") do
      [] ->
        delete_session(conn, :referer)

      [referer] ->
        put_session(conn, :referer, referer)
    end
  end
end
