defmodule DailybitsWeb.ObjectLive.Index do
  use DailybitsWeb, :live_view

  alias Dailybits.Library

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Objects")
     |> assign(:objects, Library.list_objects())}
  end
end
