defmodule DailybitsWeb.HighlightComponents do
  @moduledoc """
  Shared UI for highlight blocks (metadata tooltips, etc.).
  """
  use Phoenix.Component

  import DailybitsWeb.CoreComponents, only: [icon: 1]

  alias Dailybits.Library.Highlight

  @doc """
  Info icon that reveals highlight metadata on hover or keyboard focus.
  Does not wrap the quote — place beside the blockquote in a flex row.
  """
  attr :highlight, Highlight, required: true

  def metadata_tooltip(assigns) do
    h = assigns.highlight
    accent = accent_hex(h.color)

    assigns =
      assigns
      |> assign(:accent, accent)
      |> assign(:has_location?, h.location && String.trim(to_string(h.location)) != "")
      |> assign(:has_accessed?, not is_nil(h.last_accessed))

    ~H"""
    <div class="group relative shrink-0 pt-0.5">
      <button
        type="button"
        class="rounded p-1 text-base-content/35 transition hover:bg-base-200 hover:text-base-content/70 focus:outline-none focus-visible:ring-2 focus-visible:ring-base-content/20"
        aria-label="Highlight details"
      >
        <.icon name="hero-information-circle" class="size-5" />
      </button>

      <div
        class="pointer-events-none absolute right-0 top-full z-30 mt-1.5 w-max min-w-[12rem] max-w-[min(20rem,calc(100vw-2rem))] opacity-0 transition duration-150 group-hover:pointer-events-auto group-hover:opacity-100 group-focus-within:pointer-events-auto group-focus-within:opacity-100"
        role="tooltip"
      >
        <div class="rounded-md border border-base-300 bg-base-200/95 px-3 py-2.5 text-[11px] leading-snug text-base-content/90 shadow-md backdrop-blur-sm ring-1 ring-base-300/50">
          <dl class="space-y-2">
            <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
              <dt class="shrink-0 text-base-content/50">Marker</dt>
              <dd class="flex min-w-0 items-center gap-2">
                <span
                  class="inline-block h-2 w-10 shrink-0 rounded-full ring-1 ring-base-300/40"
                  style={"background-color: #{@accent}"}
                />
                <span class="font-mono text-[10px] text-base-content/70">{@accent}</span>
              </dd>
            </div>

            <%= if @has_location? do %>
              <div class="flex flex-wrap gap-x-2 gap-y-0.5">
                <dt class="shrink-0 text-base-content/50">Location</dt>
                <dd class="min-w-0 break-words text-base-content/85">{@highlight.location}</dd>
              </div>
            <% end %>

            <%= if @has_accessed? do %>
              <div class="flex flex-wrap gap-x-2 gap-y-0.5">
                <dt class="shrink-0 text-base-content/50">Highlighted</dt>
                <dd
                  class="text-base-content/85"
                  title={Calendar.strftime(@highlight.last_accessed, "%Y-%m-%d %H:%M:%S UTC")}
                >
                  {Calendar.strftime(@highlight.last_accessed, "%B %-d, %Y · %H:%M UTC")}
                </dd>
              </div>
            <% end %>
          </dl>
        </div>
      </div>
    </div>
    """
  end

  defp accent_hex(color) when is_binary(color) do
    case String.downcase(String.trim(color)) do
      "yellow" -> "#cb912f"
      "blue" -> "#337ea9"
      "pink" -> "#ad1a72"
      "orange" -> "#d9730d"
      "red" -> "#e03e3e"
      "green" -> "#448361"
      "purple" -> "#9065b0"
      _ -> "#787774"
    end
  end

  defp accent_hex(_), do: "#787774"
end
