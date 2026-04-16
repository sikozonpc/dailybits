defmodule DailybitsWeb.PageController do
  use DailybitsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
