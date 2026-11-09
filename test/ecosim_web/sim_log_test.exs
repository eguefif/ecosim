defmodule EcosimWeb.SimLogTest do
  # Not async: the global logger level is raised to :info for these tests.
  use EcosimWeb.ConnCase, async: false

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest

  setup do
    level = Logger.level()
    Logger.configure(level: :info)
    on_exit(fn -> Logger.configure(level: level) end)
  end

  test "logs sim start and result with client information", %{conn: conn} do
    conn =
      conn
      |> put_req_header("user-agent", "TestBrowser/1.0\nevent=forged")
      |> put_req_header("x-forwarded-for", "10.0.0.1, 203.0.113.7")
      |> put_req_header("accept-language", "fr")
      |> put_connect_params(%{"timezone" => "Europe/Paris"})

    {:ok, view, _html} = live(conn, ~p"/sim/market?mode=one-for-all")

    started_log =
      capture_log([level: :info], fn ->
        view |> element("#default-list-button") |> render_click()
      end)

    result_log =
      capture_log([level: :info], fn -> render_click(view, "finish-sim", %{}) end)

    assert started_log =~
             ~s([sim] event=started sim="market" mode="one-for-all" source=example buyers=3 sellers=3)

    assert result_log =~
             ~r/\[sim\] event=result_viewed sim="market" mode="one-for-all" periods=\d+ transactions=\d+/

    for log <- [started_log, result_log] do
      # rightmost X-Forwarded-For entry: the one added by the proxy
      assert log =~ ~s(ip="203.0.113.7")
      assert log =~ ~s(locale="fr")
      assert log =~ ~s(timezone="Europe/Paris")
      # the user agent is escaped, so it cannot inject a fake log line
      assert log =~ ~s(user_agent="TestBrowser/1.0\\nevent=forged")
      refute log =~ "\nevent=forged"
    end
  end
end
