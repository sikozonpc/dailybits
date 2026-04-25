defmodule Dailybits.Automations.Schedule do
  @doc """
  Computes the next run DateTime (UTC) for an automation graph.

  Reads the first email node's `occurrence` ("daily"/"weekly"/"monthly") and
  `time` ("HH:MM" UTC). Returns `nil` if the config is missing or invalid.
  """
  def compute_next_run_at(graph, now \\ DateTime.utc_now()) do
    with nodes when is_list(nodes) <- Map.get(graph, "nodes", []),
         %{"config" => config} <- Enum.find(nodes, &(&1["type"] == "email")),
         {:ok, time} <- parse_time(config["time"]),
         occurrence when occurrence in ["daily", "weekly", "monthly"] <- config["occurrence"] do
      next_run(occurrence, time, now)
    else
      _ -> nil
    end
  end

  defp next_run("daily", {hour, minute}, now) do
    candidate = set_time(now, hour, minute)
    if DateTime.compare(candidate, now) == :gt, do: candidate, else: shift_days(candidate, 1)
  end

  defp next_run("weekly", {hour, minute}, now) do
    candidate = set_time(now, hour, minute)

    if DateTime.compare(candidate, now) == :gt do
      candidate
    else
      shift_days(candidate, 7)
    end
  end

  defp next_run("monthly", {hour, minute}, now) do
    candidate = set_time(now, hour, minute)

    if DateTime.compare(candidate, now) == :gt do
      candidate
    else
      shift_months(candidate, 1)
    end
  end

  defp parse_time(nil), do: :error

  defp parse_time(time_str) do
    case String.split(time_str, ":") do
      [h, m] ->
        with {hour, ""} <- Integer.parse(h),
             {minute, ""} <- Integer.parse(m),
             true <- hour in 0..23 and minute in 0..59 do
          {:ok, {hour, minute}}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp set_time(dt, hour, minute) do
    %{dt | hour: hour, minute: minute, second: 0, microsecond: {0, 0}}
  end

  defp shift_days(dt, days) do
    DateTime.add(dt, days * 86_400, :second)
  end

  defp shift_months(%DateTime{year: y, month: m, day: d} = dt, months) do
    total = m + months
    new_month = rem(total - 1, 12) + 1
    new_year = y + div(total - 1, 12)
    max_day = :calendar.last_day_of_the_month(new_year, new_month)

    %{dt | year: new_year, month: new_month, day: min(d, max_day)}
  end
end
