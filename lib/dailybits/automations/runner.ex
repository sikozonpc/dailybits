defmodule Dailybits.Automations.Runner do
  require Logger

  alias Dailybits.Library
  alias Dailybits.Automations.AutomationEmail
  alias Dailybits.Mailer

  @doc """
  Runs an automation. Returns `{:ok, summary}`, `{:noop, reason}`, or `{:error, reason}`.
  """
  def run(%{graph: graph}) do
    case resolve_subgraph(graph) do
      {:noop, reason} ->
        {:noop, reason}

      {:ok, email_node, highlights_nodes} ->
        with {:ok, highlights} <- gather_inputs(email_node, highlights_nodes),
             {:ok, _email} <- dispatch(email_node, highlights) do
          {:ok, %{highlights_sent: length(highlights)}}
        end
    end
  end

  # Given a graph map, finds email nodes and their upstream highlights nodes.
  # Returns {:ok, email_node, [highlights_node]} or {:noop, reason}.
  defp resolve_subgraph(graph) do
    nodes = Map.get(graph, "nodes", [])
    connections = Map.get(graph, "connections", [])

    email_nodes = Enum.filter(nodes, &(&1["type"] == "email"))

    case email_nodes do
      [] ->
        {:noop, :no_email_node}

      [email_node | rest] ->
        if rest != [], do: Logger.warning("Runner: multiple email nodes found, using first")

        upstream = upstream_nodes(email_node["id"], nodes, connections)

        highlights_nodes = Enum.filter(upstream, &(&1["type"] == "highlights"))
        notion_nodes = Enum.filter(upstream, &(&1["type"] == "notion"))

        Enum.each(notion_nodes, fn n ->
          Logger.warning("Runner: notion node #{n["id"]} ignored (out of scope)")
        end)

        if highlights_nodes == [] do
          {:noop, :no_inputs}
        else
          {:ok, email_node, highlights_nodes}
        end
    end
  end

  # Walks connections backwards from target_id, returning all upstream nodes.
  # Uses a visited set to guard against cycles.
  defp upstream_nodes(target_id, nodes, connections) do
    nodes_by_id = Map.new(nodes, &{&1["id"], &1})
    do_upstream(target_id, nodes_by_id, connections, MapSet.new())
  end

  defp do_upstream(target_id, nodes_by_id, connections, visited) do
    if MapSet.member?(visited, target_id) do
      []
    else
      visited = MapSet.put(visited, target_id)

      direct_parents =
        connections
        |> Enum.filter(&(&1["to"] == target_id))
        |> Enum.map(& &1["from"])

      Enum.flat_map(direct_parents, fn parent_id ->
        case Map.get(nodes_by_id, parent_id) do
          nil -> []
          node -> [node | do_upstream(parent_id, nodes_by_id, connections, visited)]
        end
      end)
    end
  end

  # Fetches random highlights up to the email node's configured count, deduped by id.
  defp gather_inputs(email_node, _highlights_nodes) do
    count =
      case get_in(email_node, ["config", "highlights_count"]) do
        nil -> 5
        n when is_integer(n) -> n
        n -> String.to_integer(n)
      end
    highlights = Library.get_random_highlights(count)

    if highlights == [] do
      {:noop, :no_highlights_available}
    else
      deduped = highlights |> Enum.uniq_by(& &1.id) |> Enum.take(count)
      {:ok, deduped}
    end
  end

  defp dispatch(email_node, highlights) do
    to = get_in(email_node, ["config", "address"])

    if is_nil(to) or to == "" do
      {:error, :no_recipient}
    else
      email = AutomationEmail.highlights_digest(to, highlights)

      case Mailer.deliver(email) do
        {:ok, _} = ok -> ok
        {:error, reason} -> {:error, reason}
      end
    end
  end
end
