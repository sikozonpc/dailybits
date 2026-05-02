defmodule DailybitsWeb.LiveHooks do
  import Phoenix.Component

  def on_mount(:default, params, session, socket),
    do: on_mount(:nav, params, session, socket)

  def on_mount(:nav, _params, _session, socket) do
    {:cont, assign(socket, :active_tab, active_tab(socket.view))}
  end

  defp active_tab(DailybitsWeb.DailyLive), do: :home
  defp active_tab(DailybitsWeb.LibraryLive.Index), do: :library
  defp active_tab(DailybitsWeb.LibraryLive.Show), do: :library
  defp active_tab(DailybitsWeb.AutomationLive), do: :automations
  defp active_tab(DailybitsWeb.ObjectLive.Index), do: :objects
  defp active_tab(_), do: nil
end
