defmodule Ecosim.LogFormatter do
  @moduledoc """
  Logger formatter that prefixes each line with the date and time in UTC+1.

  Configured in `config/config.exs` together with `utc_log: true`, so the
  timestamp Logger hands us is in UTC whatever the host timezone is; we then
  shift it by a fixed one-hour offset (no daylight saving time).
  """

  @offset_seconds 3600
  @pattern Logger.Formatter.compile("$date $time $metadata[$level] $message\n")

  @doc false
  def format(level, message, timestamp, metadata) do
    Logger.Formatter.format(@pattern, level, message, shift(timestamp), metadata)
  rescue
    _ -> "could not format log message: #{inspect({level, message, timestamp, metadata})}\n"
  end

  defp shift({date, {hour, minute, second, millisecond}}) do
    {shifted_date, {h, m, s}} =
      {date, {hour, minute, second}}
      |> NaiveDateTime.from_erl!()
      |> NaiveDateTime.add(@offset_seconds)
      |> NaiveDateTime.to_erl()

    {shifted_date, {h, m, s, millisecond}}
  end
end
