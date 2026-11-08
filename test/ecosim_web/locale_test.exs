defmodule EcosimWeb.LocaleTest do
  use EcosimWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "GET /locale/:locale" do
    test "stores the locale in the session and redirects back to the referer", %{conn: conn} do
      conn =
        conn
        |> put_req_header("referer", "http://www.example.com/sim/market?mode=one-for-all")
        |> get(~p"/locale/fr")

      assert redirected_to(conn) == "/sim/market?mode=one-for-all"
      assert get_session(conn, "locale") == "fr"
    end

    test "ignores unsupported locales", %{conn: conn} do
      conn = get(conn, ~p"/locale/xx")

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, "locale") == "en"
    end

    test "does not redirect to an external referer", %{conn: conn} do
      conn =
        conn
        |> put_req_header("referer", "https://evil.example.org/phish")
        |> get(~p"/locale/fr")

      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "locale resolution" do
    test "does not leak the locale between requests in the same process", %{conn: conn} do
      {:ok, _view, _html} =
        conn |> init_test_session(%{"locale" => "fr"}) |> live(~p"/create-sim")

      {:ok, view, _html} = live(build_conn(), ~p"/create-sim")

      assert has_element?(view, "header", "Create a simulation")
    end

    test "defaults to english", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/create-sim")

      assert has_element?(view, "header", "Create a simulation")
    end

    test "uses the accept-language header", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> put_req_header("accept-language", "fr-CA,fr;q=0.9,en;q=0.8")
        |> live(~p"/create-sim")

      assert has_element?(view, "header", "Créer une simulation")
    end

    test "the session locale wins over the header and applies to LiveViews", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept-language", "en")
        |> init_test_session(%{"locale" => "fr"})

      {:ok, view, html} = live(conn, ~p"/create-sim")

      assert html =~ ~s(lang="fr")
      assert has_element?(view, "header", "Créer une simulation")
      # The selector lives in the root layout, outside the LiveView's own tree
      assert html
             |> LazyHTML.from_document()
             |> LazyHTML.query("#locale-fr[aria-current]")
             |> Enum.count() == 1
    end
  end
end
