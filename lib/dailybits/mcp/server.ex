defmodule Dailybits.Mcp.Server do
  use Anubis.Server,
    name: "dailybits-mcp",
    version: "1.0.0",
    capabilities: [:tools]

  # Static component registration — dispatches to MyApp.Echo.execute/2
  component(Dailybits.Mcp.Tools.GetDailyHighlights)

  @impl true
  def init(_client_info, frame) do
    # You can also register tools dynamically at runtime via the Frame:
    # frame = register_tool(frame, "dynamic_tool", description: "...", input_schema: %{...})
    {:ok, frame}
  end
end
