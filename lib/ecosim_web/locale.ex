defmodule EcosimWeb.Locale do
  @moduledoc """
  Resolves and applies the user's locale.

  The locale is resolved in this order:

    1. the `"locale"` value stored in the session (set by the language selector)
    2. the browser's `accept-language` header
    3. `default/0` (a fixed value, not the process locale, which may have been
       set by a previous request on the same keep-alive connection)

  Used as a plug in the browser pipeline and as an `on_mount` hook for LiveViews,
  since LiveView processes do not inherit the locale set during the HTTP request.
  """

  import Plug.Conn

  @backend EcosimWeb.Gettext
  @default_locale "en"

  @doc "The locale used when none can be resolved."
  def default, do: @default_locale

  @doc "The locales supported by the application."
  def supported, do: Gettext.known_locales(@backend)

  @doc "Returns true when the given locale is supported."
  def supported?(locale) when is_binary(locale), do: locale in supported()
  def supported?(_), do: false

  ## Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      case get_session(conn, "locale") do
        locale when is_binary(locale) ->
          if supported?(locale), do: locale, else: from_header(conn)

        _ ->
          from_header(conn)
      end

    Gettext.put_locale(@backend, locale)
    put_session(conn, "locale", locale)
  end

  defp from_header(conn) do
    conn
    |> get_req_header("accept-language")
    |> List.first("")
    |> String.split(",", trim: true)
    |> Enum.map(fn tag ->
      tag |> String.split(";") |> hd() |> String.trim() |> String.split("-") |> hd()
    end)
    |> Enum.map(&String.downcase/1)
    |> Enum.find(@default_locale, &supported?/1)
  end

  ## LiveView

  def on_mount(:default, _params, session, socket) do
    locale =
      case session do
        %{"locale" => locale} -> if supported?(locale), do: locale, else: @default_locale
        _ -> @default_locale
      end

    Gettext.put_locale(@backend, locale)

    {:cont, socket}
  end
end
