defmodule DailybitsWeb.Router do
  use DailybitsWeb, :router

  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DailybitsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DailybitsWeb do
    pipe_through :browser

    live "/", DailyLive, :index
    live "/library", LibraryLive.Index, :index
    live "/books/:id", LibraryLive.Show, :show
    live "/automations", AutomationLive, :index
    live "/objects", ObjectLive.Index, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", DailybitsWeb do
    pipe_through :api

    scope "/capture" do
      post "/sync", CaptureController, :sync
      post "/web", CaptureController, :web
    end

    post "/highlights/sync", HighlightController, :sync
    get "/highlights/daily-insights", HighlightController, :daily

    resources "/books", BookController, except: [:new, :edit]

    resources "/highlights", HighlightController, except: [:new, :edit]
  end


  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:dailybits, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DailybitsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/" do
      pipe_through :browser

      oban_dashboard("/oban")
    end
  end
end
