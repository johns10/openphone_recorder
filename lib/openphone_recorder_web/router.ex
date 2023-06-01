defmodule OpenphoneRecorderWeb.Router do
  use OpenphoneRecorderWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :cache_body
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {OpenphoneRecorderWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  def cache_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    update_in(conn.assigns[:raw_body], &[body | &1 || []])
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OpenphoneRecorderWeb do
    pipe_through :browser

    live "/", IndexLive.Index, :index
    live "/conversation/:conversation_id", IndexLive.Index, :index

    resources "/events", EventController, except: [:new, :edit]

    live "/conversations", ConversationLive.Index, :index
    live "/conversations/:id", ConversationLive.Show, :show

    live "/contacts", ContactLive.Index, :index
    live "/contacts/new", ContactLive.Index, :new
    live "/contacts/:id/edit", ContactLive.Index, :edit

    live "/contacts/:id", ContactLive.Show, :show
    live "/contacts/:id/show/edit", ContactLive.Show, :edit

    live "/summarizers", SummarizerLive.Index, :index
    live "/summarizers/new", SummarizerLive.Index, :new
    live "/summarizers/:id/edit", SummarizerLive.Index, :edit

    live "/summarizers/:id", SummarizerLive.Show, :show
    live "/summarizers/:id/show/edit", SummarizerLive.Show, :edit
  end

  scope "/api", OpenphoneRecorderWeb do
    pipe_through :api

    resources "/events", EventController, except: [:new, :edit]
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:openphone_recorder, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OpenphoneRecorderWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
