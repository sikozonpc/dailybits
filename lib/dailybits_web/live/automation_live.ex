defmodule DailybitsWeb.AutomationLive do
  use DailybitsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Automations")
     |> assign(:nodes, %{})
     |> assign(:connections, [])
     |> assign(:selected_node_id, nil)
     |> assign(:next_id, 1)}
  end

  @impl true
  def handle_event("add_node", %{"type" => type, "x" => x, "y" => y}, socket) do
    id = socket.assigns.next_id

    node = %{
      id: id,
      type: type,
      x: x,
      y: y,
      config: default_config(type)
    }

    {:noreply,
     socket
     |> assign(:nodes, Map.put(socket.assigns.nodes, id, node))
     |> assign(:next_id, id + 1)
     |> assign(:selected_node_id, id)}
  end

  def handle_event("move_node", %{"id" => id, "x" => x, "y" => y}, socket) do
    nodes =
      Map.update!(socket.assigns.nodes, id, fn node ->
        %{node | x: x, y: y}
      end)

    {:noreply, assign(socket, :nodes, nodes)}
  end

  def handle_event("select_node", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_node_id, id)}
  end

  def handle_event("deselect", _params, socket) do
    {:noreply, assign(socket, :selected_node_id, nil)}
  end

  def handle_event("connect_nodes", %{"from" => from_id, "to" => to_id}, socket) do
    already_exists =
      Enum.any?(socket.assigns.connections, fn c ->
        c.from == from_id and c.to == to_id
      end)

    if already_exists do
      {:noreply, socket}
    else
      connection = %{from: from_id, to: to_id}
      {:noreply, assign(socket, :connections, [connection | socket.assigns.connections])}
    end
  end

  def handle_event("delete_node", %{"id" => id}, socket) do
    selected =
      if socket.assigns.selected_node_id == id,
        do: nil,
        else: socket.assigns.selected_node_id

    {:noreply,
     socket
     |> assign(:nodes, Map.delete(socket.assigns.nodes, id))
     |> assign(
       :connections,
       Enum.reject(socket.assigns.connections, &(&1.from == id or &1.to == id))
     )
     |> assign(:selected_node_id, selected)}
  end

  def handle_event("update_node_config", %{"node_id" => id_str} = params, socket) do
    id = String.to_integer(id_str)
    config_fields = Map.drop(params, ["node_id", "_target"])

    nodes =
      Map.update!(socket.assigns.nodes, id, fn node ->
        %{node | config: Map.merge(node.config, config_fields)}
      end)

    {:noreply, assign(socket, :nodes, nodes)}
  end

  defp default_config("notion"), do: %{"api_key" => "", "database_id" => ""}

  defp default_config("email"),
    do: %{"address" => "", "occurrence" => "daily", "time" => "08:00", "highlights_count" => "3"}

  defp default_config("highlights"), do: %{"scope" => "daily"}

  defp default_config(_), do: %{}

  def node_title("notion"), do: "Notion"
  def node_title("email"), do: "Email"
  def node_title("highlights"), do: "Highlights"
  def node_title(_), do: "Unknown"

  def node_description("notion"), do: "Read from or sync highlights to a Notion database"
  def node_description("email"), do: "Send digest email with highlights"

  def node_description("highlights"),
    do: "Choose daily batch or full library; connect to Notion or Email"

  def node_description(_), do: ""

  def node_header_class("notion"), do: "bg-neutral text-neutral-content"
  def node_header_class("email"), do: "bg-info text-info-content"
  def node_header_class("highlights"), do: "bg-secondary text-secondary-content"
  def node_header_class(_), do: "bg-base-200"

  def has_input_port?("email"), do: true
  def has_input_port?("highlights"), do: true
  def has_input_port?("notion"), do: true
  def has_input_port?(_), do: false

  def has_output_port?("notion"), do: true
  def has_output_port?("highlights"), do: true
  def has_output_port?(_), do: false
end
