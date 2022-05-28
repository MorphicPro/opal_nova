defmodule OpalNovaWeb.LiveHelpers do
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias OpalNovaWeb.NavLive
  alias Phoenix.LiveView.JS

  alias OpalNovaWeb.Router.Helpers, as: Routes

  import OpalNovaWeb.Dissolver.Live.Tailwind

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.post_index_path(@socket, :index)}>
        <.live_component
          module={OpalNovaWeb.Admin.PostLive.FormComponent}
          id={@post.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.post_index_path(@socket, :index)}
          post: @post
        />
      </.modal>
  """
  def modal(assigns) do
    assigns = assign_new(assigns, :return_to, fn -> nil end)

    ~H"""
    <div id="modal" class="phx-modal fade-in" phx-remove={hide_modal()}>
      <div
        id="modal-content"
        class="phx-modal-content fade-in-scale"
        phx-click-away={JS.dispatch("click", to: "#close")}
        phx-window-keydown={JS.dispatch("click", to: "#close")}
        phx-key="escape"
      >
        <%= if @return_to do %>
          <%= live_patch "✖",
            to: @return_to,
            id: "close",
            class: "phx-modal-close",
            phx_click: hide_modal()
          %>
        <% else %>
          <a id="close" href="#" class="phx-modal-close" phx-click={hide_modal()}>✖</a>
        <% end %>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end

  def post_layout(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:page_header, fn -> [] end)
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <div class={@class <> " max-w-7xl mx-auto px-4 sm:px-6 md:px-8"}>
      <div class="sticky top-0 z-10 flex-shrink-0 flex h-16 bg-white border-b border-gray-200">
        <button
          phx-click={NavLive.show_nav()}
          type="button"
          class="px-4 border-r border-gray-200 text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-gray-900 lg:hidden">
          <span class="sr-only">Open sidebar</span>
          <FontAwesome.LiveView.icon name="ellipsis" type="solid" class="h-6 w-6 fill-current" />
        </button>

        <%= render_slot(@page_header) %>
      </div>

      <main class="flex-1">
        <div class="py-6">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
            <div class="py-4">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  def page_layout(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:page_header, fn -> [] end)
      |> assign_new(:class, fn -> "" end)

    ~H"""
    <div class={@class <> " lg:pl-64 flex flex-col w-0 flex-1"}>
      <div class="sticky top-0 z-10 flex-shrink-0 flex h-16 bg-white border-b border-gray-200">
        <button
          phx-click={NavLive.show_nav()}
          type="button"
          class="px-4 border-r border-gray-200 text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-gray-900 lg:hidden">
          <span class="sr-only">Open sidebar</span>
          <FontAwesome.LiveView.icon name="ellipsis" type="solid" class="h-6 w-6 fill-current" />
        </button>

        <%= render_slot(@page_header) %>
      </div>

      <main class="flex-1">
        <div class="py-6">
          <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
            <%= render_slot(@title) %>
          </div>
          <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
            <div class="py-4">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  def page_header(assigns) do
    assigns =
      assigns
      |> assign_new(:left, fn -> [] end)
      |> assign_new(:right, fn -> [] end)

    ~H"""
    <div class="flex-1 px-4 flex justify-between">
      <div class="flex-1 flex">
        <%= render_slot(@left) %>
      </div>
      <div class="ml-4 flex items-center md:ml-6">
        <%= render_slot(@right) %>
      </div>
    </div>
    """
  end

  def search(assigns) do
    ~H"""
    <.form
    id="search-form"
    for={:search}
    phx-change="search"
    phx-submit="save"
    class="w-full flex lg:ml-0"
    >

      <label for="search-field" class="sr-only">Search</label>
      <div class="relative w-full text-gray-400 focus-within:text-gray-600">
        <div class="absolute inset-y-0 left-0 flex items-center pointer-events-none">
          <FontAwesome.LiveView.icon name="magnifying-glass" type="solid" class="h-4 w-4 fill-current" />
        </div>
        <input id="search-field" class="block w-full h-full pl-8 pr-3 py-2 border-transparent text-gray-900 placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-0 focus:border-transparent sm:text-sm" placeholder="Search" type="search" name="search">
      </div>
    </.form>
    """
  end

  def user_nav(assigns) do
    assigns =
      assigns
      |> assign_new(:login, fn -> nil end)
      |> assign_new(:current_user, fn -> nil end)

    ~H"""
    <!-- Profile dropdown -->
    <div class="ml-3 relative">
      <div
        id="user-menu-button"
        phx-click={show_user_menu()}
        phx-click-away={hide_user_menu()}
        phx-window-keydown={hide_user_menu()}
        phx-key="escape"
        type="button"
        >
        <div
          class="max-w-xs bg-white flex items-center text-sm rounded-full focus:outline-none"
          aria-expanded="false"
          aria-haspopup="true">
          <%= if @current_user do %>
          <span class="mr-4 text-lg font-bold hidden lg:block xl:block 2xl:block"><%= @current_user.email %></span>
          <span class="sr-only">Open user menu</span>
          <FontAwesome.LiveView.icon name="circle-user" type="solid" class="h-8 w-8 fill-current" />
          <% else %>
            <a href={@login}>
              <span class="mr-4 text-sm font-bold hidden lg:block xl:block 2xl:block">Log in</span>
            </a>
            <a href={@register}>
              <span class="mr-4 text-sm font-bold hidden lg:block xl:block 2xl:block bg-slate-700 text-slate-100 p-2 rounded">Register</span>
            </a>
          <% end %>
        </div>
      </div>

      <%= if @current_user do %>
      <div id="user-menu" class="origin-top-right absolute right-0 mt-2 w-72 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none" style="display: none">
        <%= if @current_user.admin do %>
          <a  href="/admin" class="block px-4 py-2 text-sm text-gray-700" role="menuitem" tabindex="-1">
            <FontAwesome.LiveView.icon name="table-list" type="solid" class="inline h-4 w-4 fill-current" />
            <span class="ml-2">Admin</span>
          </a>
        <% end %>
        <span class="px-4 py-2 block text-sm font-bold lg:hidden xl:hidden 2xl:hidden">
          <FontAwesome.LiveView.icon name="user" type="solid" class="inline h-4 w-4 fill-current" />
          <span class="pl-2"><%= @current_user.email %></span>
        </span>
        <%= live_redirect to: "/users/settings", class: "block px-4 py-2 text-sm text-gray-700", role: "menuitem", tabindex: "-1" do %>
          <FontAwesome.LiveView.icon name="toolbox" type="solid" class="inline h-4 w-4 fill-current" />
          <span class="ml-2">Settings</span>
        <% end %>
        <a  href="/users/log_out" class="block px-4 py-2 text-sm text-gray-700" role="menuitem" tabindex="-1">
          <FontAwesome.LiveView.icon name="lock" type="solid" class="inline h-4 w-4 fill-current" />
          <span class="ml-2">Log out</span>
        </a>
      </div>
      <% end %>
    </div>
    """
  end

  defp show_user_menu(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#user-menu",
      transition:
        {"transition ease-in-out duration-150", "opacity-0 scale-95", "opacity-100 scale-100"}
    )
  end

  defp hide_user_menu(js \\ %JS{}) do
    js
    |> JS.hide(to: "#user-menu", transition: "fade-out")
  end

  def toggle_draft_field(%{changes: %{draft: value}}), do: value
  def toggle_draft_field(%{data: %{draft: value}}), do: value

  def description_length(%{changes: %{description: value}}), do: value |> String.length()
  def description_length(%{data: %{description: nil}}), do: 0
  def description_length(%{data: %{description: value}}), do: value |> String.length()
  def description_length(_), do: 0

  def parse_markdown(nil) do
    ""
  end

  def parse_markdown(text) do
    case Earmark.as_html(text, pure_links: true) do
      {:ok, html_doc, _} ->
        html_doc

      {:error, _html_doc, error_messages} ->
        error_messages
        |> Enum.reduce("", fn error, acc ->
          {type, line_number, issue} = error
          acc <> "#{type} on line #{line_number} | #{issue}" <> "\n"
        end)
    end
  end

  def ordinale(string) when is_binary(string) do
    string
    |> String.to_integer()
    |> ordinale()
  end

  def ordinale(number) when is_integer(number) and number >= 0 do
    [to_string(number), suffix(number)]
    |> IO.iodata_to_binary()
  end

  def ordinale(number), do: number

  defp suffix(num) when is_integer(num) and num > 100,
    do: rem(num, 100) |> suffix()

  defp suffix(num) when num in 11..13, do: "th"
  defp suffix(num) when num > 10, do: rem(num, 10) |> suffix()
  defp suffix(1), do: "st"
  defp suffix(2), do: "nd"
  defp suffix(3), do: "rd"
  defp suffix(_), do: "th"

  def published_date(date) do
    "#{date |> Calendar.strftime("%A, %B")} #{date |> Calendar.strftime("%d") |> ordinale()} #{date |> Calendar.strftime("%Y")}"
  end

  def published?(%{draft: true}), do: false

  def published?(%{draft: false, published_at: published_at}) do
    case Date.compare(published_at, Date.utc_today()) do
      :eq ->
        true

      :gt ->
        false

      :lt ->
        true
    end
  end

  def post_paginate_helper(socket, :tag) do
    &Routes.fe_post_tag_path(socket, :tag, &1)
  end

  def post_paginate_helper(socket, :tag, scope) do
    &Routes.fe_post_tag_path(socket, :tag, scope, &1)
  end

  def post_paginate_helper(socket, action, nil) do
    &Routes.fe_post_index_path(socket, action, &1)
  end

  def post_paginate_helper(socket, action, scope) do
    &Routes.fe_post_index_path(socket, action, &1)
  end

  def parse_tags(content, url) do
    String.replace(content, ~r/(#\w+)/, fn match ->
      {:safe, html} = live_patch(match, to: url.(match |> String.replace("#", "")))
      html
    end)
  end

  def admin?(%{admin: true}), do: true
  def admin?(_), do: false
end
