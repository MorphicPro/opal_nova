defmodule OpalNovaWeb.NavLive do
  use OpalNovaWeb, :live_component
  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div>
      <.off_canvas_mobile_menu links={@links} />
      <.static_desktop_sidebar links={@links} />
    </div>
    """
  end

  defp off_canvas_mobile_menu(assigns) do
    ~H"""
    <!-- Off-canvas menu for mobile, show/hide based on off-canvas menu state. -->
    <div
      id="off-canvas-mobile"
      class="fixed inset-0 flex z-40 lg:hidden"
      role="dialog"
      aria-modal="true"
      style="display:none;"
    >
      <!--
        Off-canvas menu overlay, show/hide based on off-canvas menu state.

        Entering: "transition-opacity ease-linear duration-300"
          From: "opacity-0"
          To: "opacity-100"
        Leaving: "transition-opacity ease-linear duration-300"
          From: "opacity-100"
          To: "opacity-0"
      -->
      <div
        id="off-canvas-mobile-menu-overlay"
        class="fixed inset-0 bg-gray-600 bg-opacity-75"
        aria-hidden="true"
        phx-click={JS.dispatch("click", to: "#nav-close")}
        phx-window-keydown={JS.dispatch("click", to: "#nav-close")}
        phx-key="escape"
        style="display:none;">
      </div>

      <!--
        Off-canvas menu, show/hide based on off-canvas menu state.

        Entering: "transition ease-in-out duration-300 transform"
          From: "-translate-x-full"
          To: "translate-x-0"
        Leaving: "transition ease-in-out duration-300 transform"
          From: "translate-x-0"
          To: "-translate-x-full"
      -->
      <div
        id="off-canvas-menu"
        class="relative flex-1 flex flex-col max-w-xs w-full pt-5 pb-4 bg-gray-800"
        style="display:none;"
        >
        <!--
          Close button, show/hide based on off-canvas menu state.

          Entering: "ease-in-out duration-300"
            From: "opacity-0"
            To: "opacity-100"
          Leaving: "ease-in-out duration-300"
            From: "opacity-100"
            To: "opacity-0"
        -->
        <div
          id="mobile-close"
          class="absolute top-0 right-0 -mr-12 pt-2"
          style="display:none;"
          >
          <button id="nav-close" phx-click={hide_nav()}, type="button" class="ml-1 flex items-center justify-center h-10 w-10 rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white">
            <span class="sr-only">Close sidebar</span>
            <FontAwesome.LiveView.icon name="circle-xmark" type="regular" class="h-6 w-6 text-white fill-current" />
          </button>
        </div>

        <div class="flex-shrink-0 flex items-center px-4">
          <span class="text-gray-100 text-xl font-black">Opal Nova Admin</span>
        </div>
        <div class="mt-5 flex-1 h-0 overflow-y-auto">
          <nav class="px-2">
            <div class="space-y-1">
              <%= render_slot(@links) %>
            </div>
          </nav>
        </div>
      </div>

      <div class="flex-shrink-0 w-14" aria-hidden="true">
        <!-- Dummy element to force sidebar to shrink to fit close icon -->
      </div>
    </div>
    """
  end

  defp static_desktop_sidebar(assigns) do
    ~H"""
    <div class="hidden lg:flex lg:w-64 lg:fixed lg:inset-y-0">
      <div class="flex-1 flex flex-col min-h-0">
        <div class="flex items-center h-16 flex-shrink-0 px-4 bg-gray-900">
          <span class="text-gray-100 text-xl font-black">Opal Nova Admin</span>
        </div>
        <div class="flex-1 flex flex-col overflow-y-auto bg-gray-800">
          <nav class="flex-1 px-2 py-4">
            <div class="space-y-1">
              <%= render_slot(@links) %>
            </div>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  def link(assigns) do
    assigns =
      assigns
      |> assign_new(:path, fn -> "#" end)
      |> assign_new(:active, fn -> false end)
      |> assign_new(:icon, fn -> [] end)
      |> assign_new(:base_class, fn -> "group nav-link" end)
      |> assign_new(:active_class, fn -> "current" end)
      |> assign_new(:inactive_class, fn -> "inactive" end)
      |> assign_new(:class, fn %{
                                 active: active,
                                 base_class: base_class,
                                 active_class: active_class,
                                 inactive_class: inactive_class
                               } ->
        if active,
          do: active_class <> " " <> base_class,
          else: inactive_class <> " " <> base_class
      end)

    ~H"""
    <%= live_redirect to: @path, class: @class, "aria-current": "page" do %>
      <%= render_slot(@icon) %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  def icon(assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:active, fn -> false end)
      |> assign_new(:type, fn -> nil end)
      |> assign_new(:base_class, fn -> "icon" end)
      |> assign_new(:active_class, fn -> "icon-active" end)
      |> assign_new(:inactive_class, fn -> "icon-inactive" end)
      |> assign_new(:class, fn %{
                                 active: active,
                                 base_class: base_class,
                                 active_class: active_class,
                                 inactive_class: inactive_class
                               } ->
        if active,
          do: active_class <> " " <> base_class,
          else: inactive_class <> " " <> base_class
      end)

    ~H"""
    <FontAwesome.LiveView.icon name={@name} type={@type} class={@class} />
    """
  end

  def hide_nav(js \\ %JS{}) do
    js
    |> JS.hide(to: "#off-canvas-mobile-menu-overlay", transition: "fade-out")
    |> JS.hide(
      to: "#off-canvas-menu",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"}
    )
    |> JS.hide(to: "#off-canvas-mobile", transition: "fade-out")
    |> JS.hide(to: "#mobile-close", transition: "fade-out", time: 200)
  end

  def show_nav(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#off-canvas-mobile-menu-overlay",
      transition: {"transition ease-in-out duration-150", "opacity-0", "opacity-100"},
      display: "flex"
    )
    |> JS.show(
      to: "#off-canvas-menu",
      display: "flex",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}
    )
    |> JS.show(to: "#off-canvas-mobile", transition: "fade-in", display: "flex")
    |> JS.show(to: "#mobile-close", transition: "fade-in-slow", time: 1000, display: "flex")
  end
end
