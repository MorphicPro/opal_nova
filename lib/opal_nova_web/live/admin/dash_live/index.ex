defmodule OpalNovaWeb.Admin.DashLive.Index do
  use OpalNovaWeb, :live_view_admin

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout>

      <:page_header>
        <.page_header>
          <:right>
            <.user_nav current_user={@current_user} login={Routes.user_session_path(@socket, :new)} register={Routes.user_registration_path(@socket, :new)} />
          </:right>
        </.page_header>
      </:page_header>
      <:title>
        <h1 class="text-xl font-semibold text-gray-900">Dashboard</h1>
      </:title>

      Craps
    </.page_layout>
    """
  end
end
