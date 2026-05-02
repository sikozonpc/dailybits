defmodule DailybitsWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use DailybitsWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :active_tab, :atom, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main class="px-6 pt-12 pb-24 sm:px-12 sm:pt-16 lg:px-16">
      <div class="mx-auto max-w-3xl">
        <nav class="mb-10 flex items-center gap-1.5 text-[13px]">
          <.link
            navigate={~p"/"}
            class={[
              "rounded px-1 py-0.5",
              if(@active_tab == :home,
                do: "bg-base-200 text-base-content font-medium",
                else: "text-base-content/50 hover:bg-base-200 hover:text-base-content"
              )
            ]}
          >
            Home
          </.link>
          <span class="text-base-content/30">/</span>
          <.link
            navigate={~p"/library"}
            class={[
              "rounded px-1 py-0.5",
              if(@active_tab == :library,
                do: "bg-base-200 text-base-content font-medium",
                else: "text-base-content/50 hover:bg-base-200 hover:text-base-content"
              )
            ]}
          >
            Library
          </.link>
          <span class="text-base-content/30">/</span>
          <.link
            navigate={~p"/automations"}
            class={[
              "rounded px-1 py-0.5",
              if(@active_tab == :automations,
                do: "bg-base-200 text-base-content font-medium",
                else: "text-base-content/50 hover:bg-base-200 hover:text-base-content"
              )
            ]}
          >
            Automations
          </.link>
          <span class="text-base-content/30">/</span>
          <.link
            navigate={~p"/objects"}
            class={[
              "rounded px-1 py-0.5",
              if(@active_tab == :objects,
                do: "bg-base-200 text-base-content font-medium",
                else: "text-base-content/50 hover:bg-base-200 hover:text-base-content"
              )
            ]}
          >
            Capture
          </.link>
        </nav>

        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
