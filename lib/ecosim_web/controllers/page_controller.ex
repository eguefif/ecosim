defmodule EcosimWeb.PageController do
  use EcosimWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
