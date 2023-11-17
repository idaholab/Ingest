defmodule IngestWeb.Router do
  use IngestWeb, :router

  import IngestWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {IngestWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", IngestWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/users/log_in/one_id", OidcController, :oneid
    get "/users/log_in/okta", OidcController, :okta
  end

  # Other scopes may use custom stacks.
  # scope "/api", IngestWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ingest, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: IngestWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", IngestWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{IngestWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", IngestWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{IngestWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/dashboard", DashboardLive, :index

      live "/dashboard/requests", RequestsLive, :index

      live "/dashboard/templates", TemplatesLive, :index
      live "/dashboard/templates/new", TemplatesLive, :new
      live "/dashboard/templates/:id", TemplateBuilderLive, :index

      live "/dashboard/destinations", DestinationsLive, :index
      live "/dashboard/destinations/register_client", DestinationsLive, :register_client

      live "/dashboard/projects", ProjectsLive, :index
      live "/dashboard/projects/new", ProjectsLive, :new
      live "/dashboard/projects/:id/", ProjectShowLive, :show
      live "/dashboard/projects/:id/edit", ProjectsLive, :edit
    end
  end

  scope "/", IngestWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{IngestWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
