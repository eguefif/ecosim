defmodule EcosimWeb.SimLog do
  @moduledoc """
  Logs simulation usage (a sim was started, results were viewed) together with
  information about the client: IP address, user agent, UI language and browser
  timezone.

  Each event is a single `info` line prefixed with `[sim]`, so production logs
  can be filtered with e.g. `docker service logs ecosim_app | grep '\\[sim\\]'`.

  Client information can only be read during `mount/3` (see
  `Phoenix.LiveView.get_connect_info/2`), so LiveViews call `client_info/1` in
  `mount/3`, keep the result in an assign and pass it to `log/3` later.
  """

  require Logger

  @type client_info :: %{
          ip: String.t() | nil,
          user_agent: String.t() | nil,
          locale: String.t(),
          timezone: String.t() | nil
        }

  @doc """
  Collects client information from the LiveView socket. Must be called in `mount/3`.

  The endpoint's `/live` socket must declare `:peer_data`, `:x_headers` and
  `:user_agent` in its `connect_info`. The timezone is sent by `assets/js/app.js`
  as a connect param, so it is only available once the socket is connected.
  """
  @spec client_info(Phoenix.LiveView.Socket.t()) :: client_info()
  def client_info(socket) do
    connect_params =
      if Phoenix.LiveView.connected?(socket),
        do: Phoenix.LiveView.get_connect_params(socket) || %{},
        else: %{}

    %{
      ip: client_ip(socket),
      user_agent: Phoenix.LiveView.get_connect_info(socket, :user_agent),
      locale: Gettext.get_locale(EcosimWeb.Gettext),
      timezone: connect_params["timezone"]
    }
  end

  @doc """
  Logs a simulation event.

  `fields` is a keyword list of event-specific details (sim, mode, counts...).
  """
  @spec log(atom(), client_info(), keyword()) :: :ok
  def log(event, client_info, fields \\ []) do
    Logger.info(fn ->
      client_fields = [
        ip: client_info.ip,
        locale: client_info.locale,
        timezone: client_info.timezone,
        user_agent: client_info.user_agent
      ]

      ["[sim] event=", Atom.to_string(event), format_fields(fields ++ client_fields)]
    end)
  end

  # Values are inspected so strings are quoted and escaped: a user agent
  # containing a newline cannot forge an extra log line.
  defp format_fields(fields) do
    Enum.map(fields, fn
      {key, nil} -> [" ", Atom.to_string(key), "=-"]
      {key, value} when is_binary(value) -> [" ", Atom.to_string(key), "=", inspect(value)]
      {key, value} -> [" ", Atom.to_string(key), "=", to_string(value)]
    end)
  end

  # In production, Traefik proxies requests and appends the address it received
  # the request from to X-Forwarded-For, so the rightmost entry is the real
  # client. Entries to its left are supplied by the client and can be spoofed.
  # Without a proxy (dev), fall back to the socket's peer address.
  defp client_ip(socket) do
    forwarded =
      (Phoenix.LiveView.get_connect_info(socket, :x_headers) || [])
      |> Enum.find_value(fn {name, value} -> name == "x-forwarded-for" && value end)

    case forwarded && forwarded |> String.split(",") |> List.last() |> String.trim() do
      ip when is_binary(ip) and ip != "" ->
        ip

      _ ->
        case Phoenix.LiveView.get_connect_info(socket, :peer_data) do
          %{address: address} -> address |> :inet.ntoa() |> to_string()
          _ -> nil
        end
    end
  end
end
