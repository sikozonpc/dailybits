defmodule DailybitsWeb.DailyLive do
  use DailybitsWeb, :live_view

  alias Dailybits.Library

  @issue_epoch ~D[2026-01-01]

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()

    {:ok,
     socket
     |> assign(:page_title, "Morning Read")
     |> assign(:today, today)
     |> assign(:issue, issue_number(today))
     |> assign(:highlights, Library.get_random_highlights(3))}
  end

  defp issue_number(date) do
    Date.diff(date, @issue_epoch) + 1
  end

  @doc """
  Returns the hex color accent (dot, rule, text) used for a highlight's color.
  """
  def highlight_accent(color), do: highlight_color(color) |> elem(0)

  @doc """
  Returns the Notion-style soft background tint for a highlight's color.
  """
  def highlight_bg(color), do: highlight_color(color) |> elem(1)

  defp highlight_color(color) when is_binary(color) do
    case String.downcase(String.trim(color)) do
      "yellow" -> {"#cb912f", "#fbf3db"}
      "blue" -> {"#337ea9", "#ddebf1"}
      "pink" -> {"#ad1a72", "#f4dfeb"}
      "orange" -> {"#d9730d", "#faebdd"}
      "red" -> {"#e03e3e", "#fbe4e4"}
      "green" -> {"#448361", "#dbeddb"}
      "purple" -> {"#9065b0", "#eae4f2"}
      _ -> {"#787774", "#f1f1ef"}
    end
  end

  defp highlight_color(_), do: {"#787774", "#f1f1ef"}
end
