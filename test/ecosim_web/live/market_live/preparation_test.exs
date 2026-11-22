defmodule EcosimWeb.MarketLive.PreparationTest do
  use EcosimWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Ecosim.SimServer

  # Starts a market simulation the way CreateSimLive does, then hands it over
  # to the MarketLive mounted by the test.
  setup %{conn: conn} do
    {:ok, sim_id} = SimServer.start()
    :ok = SimServer.set_sim_type(sim_id, :market)
    :ok = SimServer.set_sim_mode(sim_id, :one_for_all)
    :ok = SimServer.add_participants_to_simulation(sim_id, ["Alice", "Bruno", "Chloé", "David"])
    :ok = SimServer.create_simulation(sim_id)

    {:ok, view, _html} = live(conn, ~p"/sim/market/#{sim_id}")

    %{view: view, sim_id: sim_id}
  end

  defp upload_actors_file(view, content) do
    view
    |> file_input("#actors-upload-form", :actors_file, [
      %{name: "market-actors.csv", content: content, type: "text/csv"}
    ])
    |> render_upload("market-actors.csv")

    view |> form("#actors-upload-form") |> render_submit()
  end

  test "lists the actors and offers the actors file for download", %{view: view} do
    assert has_element?(view, "#buyers-table td", "Alice")
    assert has_element?(view, "#sellers-table td", "Chloé")

    assert has_element?(
             view,
             "#preparation-actions #download-actors[download='market-actors.csv']"
           )
  end

  test "buttons under the market models toggle the upload form and the actors tables, hidden by default",
       %{view: view} do
    assert has_element?(
             view,
             "#actors-controls #toggle-actors-upload[aria-controls='actors-upload-panel'][aria-expanded='false']"
           )

    assert has_element?(view, "#actors-upload-panel[style='display: none'] #actors-upload-form")

    assert has_element?(
             view,
             "#actors-controls #toggle-actors-tables[aria-controls='actors-tables'][aria-expanded='false']"
           )

    assert has_element?(view, "#actors-tables[style='display: none'] #buyers-table")
  end

  test "uploading an actors file replaces the market's actors", %{view: view} do
    upload_actors_file(view, "role,name,wt\nbuyer,Zoé,120\nseller,Yann,80\nseller,Xavier,85\n")

    assert has_element?(view, "#buyers-table td", "Zoé")
    assert has_element?(view, "#sellers-table td", "Xavier")
    refute has_element?(view, "#buyers-table td", "Alice")
    assert has_element?(view, "#flash-info")
  end

  test "an invalid actors file keeps the actors and shows the error", %{view: view} do
    upload_actors_file(view, "role,name,wt\nbuyer,Zoé,120\nboss,Yann,80\n")

    assert has_element?(view, "#flash-error", "Line 3")
    assert has_element?(view, "#buyers-table td", "Alice")
  end
end
