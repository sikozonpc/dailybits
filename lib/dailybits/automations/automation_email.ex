defmodule Dailybits.Automations.AutomationEmail do
  import Swoosh.Email

  @from {"Dailybits", "noreply@dailybits.local"}

  def highlights_digest(to, highlights) do
    new()
    |> from(@from)
    |> to(to)
    |> subject("Your Dailybits digest — #{length(highlights)} highlights")
    |> html_body(html(highlights))
    |> text_body(text(highlights))
  end

  defp html(highlights) do
    items =
      Enum.map_join(highlights, "\n", fn h ->
        color = color_style(h.color)

        """
        <div style="border-left: 4px solid #{color}; padding: 8px 16px; margin: 12px 0;">
          <p style="margin: 0; font-size: 15px;">#{h.text}</p>
          #{if h.book, do: ~s(<p style="margin: 4px 0 0; font-size: 12px; color: #888;">#{h.book.title}</p>), else: ""}
        </div>
        """
      end)

    """
    <html><body style="font-family: sans-serif; max-width: 600px; margin: auto; padding: 24px;">
      <h2 style="font-size: 18px; color: #111;">Your highlights</h2>
      #{items}
    </body></html>
    """
  end

  defp text(highlights) do
    Enum.map_join(highlights, "\n\n", fn h ->
      book = if h.book, do: " — #{h.book.title}", else: ""
      "#{h.text}#{book}"
    end)
  end

  defp color_style("yellow"), do: "#FFD966"
  defp color_style("blue"), do: "#9FC5E8"
  defp color_style("pink"), do: "#EA9999"
  defp color_style("orange"), do: "#F9CB9C"
  defp color_style(_), do: "#CCCCCC"
end
