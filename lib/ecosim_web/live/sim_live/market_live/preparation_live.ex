defmodule EcosimWeb.SimLive.MarketLive.PreparationLive do
  @moduledoc """
  Preparation step of the market simulation: download or upload the actors
  file, look at the actors, and choose the market model.

  The parent LiveView must `allow_upload(:actors_file, ...)` and handle the
  `start`, `select-model`, `validate_actors_upload`, `cancel_actors_upload` and
  `save_actors_upload` events.
  """

  use EcosimWeb, :html

  alias Ecosim.Sim.Market.ActorsFile

  attr :info, :map, required: true, doc: "the market's preparation info"
  attr :uploads, :map, required: true

  def preparation(assigns) do
    ~H"""
    <div id="market-preparation" class="flex flex-col gap-[32px]">
      <.show_preparation_action_buttons actors={@info.actors} />

      <.show_market_model_choices market_choice={@info.market_model} />

      <div id="actors-controls" class="flex flex-col gap-[16px]">
        <div class="flex flex-row flex-wrap gap-[8px]">
          <.panel_toggle_button
            id="toggle-actors-upload"
            panel="actors-upload-panel"
            display="flex"
            icon="hero-arrow-up-tray"
          >
            {gettext("Upload actors file")}
          </.panel_toggle_button>

          <.panel_toggle_button
            id="toggle-actors-tables"
            panel="actors-tables"
            display="grid"
            icon="hero-users"
          >
            {gettext("Actors")}
            <span class="opacity-60">({length(@info.actors)})</span>
          </.panel_toggle_button>
        </div>

        <.actors_upload_panel uploads={@uploads} />
        <.actors_tables_panel actors={@info.actors} />
      </div>
    </div>
    """
  end

  attr :actors, :list, required: true

  def show_preparation_action_buttons(assigns) do
    ~H"""
    <div
      id="preparation-actions"
      class="flex flex-row flex-wrap items-center justify-between gap-[8px] shadow-md p-[16px] rounded-lg"
    >
      <div class="flex flex-row flex-wrap gap-[8px]">
        <a
          id="download-actors"
          href={"data:text/csv;charset=utf-8;base64," <> Base.encode64(ActorsFile.encode(@actors))}
          download="market-actors.csv"
          class="btn btn-secondary btn-sm transition hover:-translate-y-0.5"
        >
          <.icon name="hero-arrow-down-tray" class="size-4" />
          {gettext("Download actors file")}
        </a>
      </div>

      <button id="start-market" class="btn btn-primary w-[96px]" phx-click="start">
        {gettext("Start")}
      </button>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :panel, :string, required: true, doc: "the DOM id of the panel to show or hide"
  attr :display, :string, required: true, doc: "the panel's CSS display when shown"
  attr :icon, :string, required: true
  slot :inner_block, required: true

  @doc """
  A button that shows or hides the panel `panel`. The panel must start with
  `style="display: none"`.
  """
  def panel_toggle_button(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      aria-controls={@panel}
      aria-expanded="false"
      phx-click={toggle_panel(@id, @panel, @display)}
      class="btn btn-ghost btn-sm gap-2 transition hover:-translate-y-0.5"
    >
      <.icon name={@icon} class="size-4" />
      {render_slot(@inner_block)}
      <span class="toggle-chevron flex transition-transform duration-200">
        <.icon name="hero-chevron-down" class="size-4" />
      </span>
    </button>
    """
  end

  attr :uploads, :map, required: true

  def actors_upload_panel(assigns) do
    ~H"""
    <%!-- Hidden by default, shown by the "Upload actors file" button. --%>
    <div
      id="actors-upload-panel"
      class="flex-col gap-[16px] origin-top rounded-lg shadow-md p-[16px]"
      style="display: none"
    >
      <p class="text-sm opacity-70">
        {gettext(
          "The file lists each actor's role, name and willingness to pay (buyer) or to accept (seller). Download it, edit it, then upload it to replace the actors."
        )}
      </p>
      <.actors_upload_form uploads={@uploads} />
    </div>
    """
  end

  attr :actors, :list, required: true

  def actors_tables_panel(assigns) do
    assigns =
      assigns
      |> assign(:buyers, Enum.filter(assigns.actors, &(&1.type == :buyer)))
      |> assign(:sellers, Enum.filter(assigns.actors, &(&1.type == :seller)))

    ~H"""
    <%!-- Hidden by default, shown by the "Actors" button. --%>
    <div
      id="actors-tables"
      class="grid grid-cols-1 gap-[16px] origin-top md:grid-cols-2"
      style="display: none"
    >
      <.actors_table id="buyers-table" title={gettext("Buyers")} wt_label="WTB" actors={@buyers} />
      <.actors_table id="sellers-table" title={gettext("Sellers")} wt_label="WTA" actors={@sellers} />
    </div>
    """
  end

  attr :uploads, :map, required: true

  def actors_upload_form(assigns) do
    ~H"""
    <form
      id="actors-upload-form"
      phx-change="validate_actors_upload"
      phx-submit="save_actors_upload"
      class="flex flex-col gap-[8px]"
    >
      <label
        for={@uploads.actors_file.ref}
        phx-drop-target={@uploads.actors_file.ref}
        class="flex cursor-pointer flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed border-base-300 p-6 text-sm transition hover:border-primary hover:bg-base-200"
      >
        <.icon name="hero-arrow-up-tray" class="size-6" />
        <span>{gettext("Drop an actors file here or click to select it (.csv, .txt)")}</span>
        <.live_file_input upload={@uploads.actors_file} class="sr-only" />
      </label>

      <div :for={entry <- @uploads.actors_file.entries} id={"actors-upload-entry-#{entry.ref}"}>
        <div class="flex items-center justify-between text-sm">
          <span>{entry.client_name}</span>
          <button
            type="button"
            phx-click="cancel_actors_upload"
            phx-value-ref={entry.ref}
            aria-label={gettext("Cancel")}
            class="opacity-60 transition hover:opacity-100"
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </div>
        <progress value={entry.progress} max="100" class="w-full">{entry.progress}%</progress>
        <p :for={err <- upload_errors(@uploads.actors_file, entry)} class="text-sm text-error">
          {upload_error_to_string(err)}
        </p>
      </div>

      <p :for={err <- upload_errors(@uploads.actors_file)} class="text-sm text-error">
        {upload_error_to_string(err)}
      </p>

      <button
        type="submit"
        id="actors-upload-submit"
        disabled={@uploads.actors_file.entries == []}
        class="btn btn-primary self-start"
      >
        {gettext("Upload")}
      </button>
    </form>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :wt_label, :string, required: true
  attr :actors, :list, required: true

  def actors_table(assigns) do
    ~H"""
    <div id={@id} class="rounded-lg shadow-md p-[16px]">
      <h3 class="mb-2 font-bold">
        {@title} <span class="text-sm font-normal opacity-60">({length(@actors)})</span>
      </h3>
      <table class="w-full text-sm">
        <thead>
          <tr class="text-left opacity-60">
            <th class="py-1 font-normal">{gettext("Name")}</th>
            <th class="py-1 text-right font-normal">{@wt_label}</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={actor <- @actors} class="border-t border-base-200 transition hover:bg-base-200">
            <td class="py-1">{actor.name}</td>
            <td class="py-1 text-right font-mono">{actor.wt}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :market_choice, :integer, default: 1

  def show_market_model_choices(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="text-lg font-bold">{gettext("Choose a Market Model")}</div>
      <div class="flex flex-row gap-[32px]">
        <div class={[
          @market_choice == 1 && "aura",
          @market_choice != 1 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[194px]"
            phx-click="select-model"
            phx-value-model="1"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market1.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>

        <div class={[
          @market_choice == 2 && "aura",
          @market_choice != 2 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[194px]"
            phx-click="select-model"
            phx-value-model="2"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market2.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>

        <div class={[
          @market_choice == 3 && "aura",
          @market_choice != 3 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[194px]"
            phx-click="select-model"
            phx-value-model="3"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market3.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Shows or hides `panel` with a fade-and-slide transition, and marks the
  # button as active. Runs in the browser: no server round trip, and LiveView
  # keeps the toggled state when the page re-renders (e.g. after an upload).
  defp toggle_panel(js \\ %JS{}, button_id, panel_id, display) do
    js
    |> JS.toggle(
      to: "##{panel_id}",
      display: display,
      in:
        {"transition ease-out duration-200", "opacity-0 -translate-y-2 scale-y-95",
         "opacity-100 translate-y-0 scale-y-100"},
      out:
        {"transition ease-in duration-150", "opacity-100 translate-y-0 scale-y-100",
         "opacity-0 -translate-y-2 scale-y-95"}
    )
    |> JS.toggle_class("btn-active", to: "##{button_id}")
    |> JS.toggle_class("rotate-180", to: "##{button_id} .toggle-chevron")
    |> JS.toggle_attribute({"aria-expanded", "false", "true"}, to: "##{button_id}")
  end

  defp upload_error_to_string(:too_large), do: gettext("The file is too large.")

  defp upload_error_to_string(:not_accepted),
    do: gettext("Format not accepted (.csv or .txt only).")

  defp upload_error_to_string(:too_many_files), do: gettext("Only one file is allowed.")
  defp upload_error_to_string(_), do: gettext("Error while uploading.")
end
