defmodule OpalNovaWeb.Router do
  use OpalNovaWeb, :router

  import OpalNovaWeb.UserAuth
  import OpalNovaWeb.Plug.Log

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {OpalNovaWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :inspect_conn
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", OpalNovaWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OpalNovaWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  live_session :admin,
    root_layout: {OpalNovaWeb.LayoutView, "admin.html"},
    on_mount: OpalNovaWeb.UserAuthLive do
    scope "/admin", OpalNovaWeb do
      pipe_through [:browser, :require_authenticated_user]

      live "/posts/new", Admin.PostLive.Form, :new
      live "/posts/:id/show/edit", Admin.PostLive.Form, :edit
      live "/posts/:id", Admin.PostLive.Show, :show
      live "/posts", Admin.PostLive.Index, :index

      live "/comments", Admin.CommentLive.Index, :index
      live "/comments/:id/edit", Admin.CommentLive.Index, :edit

      live "/comments/:id", Admin.CommentLive.Show, :show
      live "/comments/:id/show/edit", Admin.CommentLive.Show, :edit

      live "/", Admin.DashLive.Index, :index
    end
  end

  live_session :user,
    root_layout: {OpalNovaWeb.LayoutView, "root.html"},
    on_mount: OpalNovaWeb.UserLive do
    scope "/", OpalNovaWeb do
      pipe_through [:browser]

      live "/posts/tags/:tag", PostLive.Index, :tag,  as: :fe_post_tag
      live "/posts/:slug", PostLive.Show, :show, as: :fe_post_show
      live "/", PostLive.Index, :index, as: :fe_post_index
    end
  end

  ## Authentication routes

  scope "/", OpalNovaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", OpalNovaWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    live_session :post_admin, on_mount: OpalNovaWeb.UserAuthLive do
    end
  end

  scope "/", OpalNovaWeb do
    pipe_through [:browser]

    get "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
