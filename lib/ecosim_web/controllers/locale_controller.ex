defmodule EcosimWeb.LocaleController do
  use EcosimWeb, :controller

  alias EcosimWeb.Locale

  @doc """
  Stores the chosen locale in the session and redirects back to the page the
  user came from (only local paths are followed).
  """
  def update(conn, %{"locale" => locale}) do
    conn =
      if Locale.supported?(locale),
        do: put_session(conn, "locale", locale),
        else: conn

    redirect(conn, to: return_path(conn))
  end

  defp return_path(conn) do
    with [referer | _] <- get_req_header(conn, "referer"),
         %URI{host: host, path: "/" <> _ = path, query: query} <- URI.parse(referer),
         true <- host == conn.host do
      if query, do: path <> "?" <> query, else: path
    else
      _ -> ~p"/"
    end
  end
end
