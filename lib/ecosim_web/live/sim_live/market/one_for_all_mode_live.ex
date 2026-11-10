defmodule EcosimWeb.SimLive.OneForAllModeLive do
  use EcosimWeb, :live_view

  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Period
  alias EcosimWeb.SimLive.Market.CommonLive

  attr :uploads, :map, required: true
  attr :market_model, :integer, default: -1

  def preparation_one_for_all_mode(assigns) do
    ~H"""
    <div class="flex flex-col gap-[16px]">
      <h2 class="text-lg font-bold">{gettext("1 - Preparation")}</h2>
      {gettext("This mode requires some preparation:")}<br />
      <ul>
        <li>
          1. {gettext("Upload a file containing the participants' names, separated by commas.")}
        </li>
        <li>
          2. {gettext(
            "Choose a supply and demand graph to define the willingness to accept and to pay (WTA and WTP)."
          )}
        </li>
        <li>
          3. {gettext("Generate the distribution of sellers and buyers with their WTA and WTP.")}
        </li>
        <li>4. {gettext("Give each participant their role and their WTA or WTP.")}</li>
      </ul>
      <pre id="preparation-file-example" class="mt-2 rounded-lg bg-base-200 p-4 font-mono text-sm">{preparation_example()}</pre>

      <form
        id="actors-upload-form"
        phx-change="validate_upload"
        phx-submit="save_upload"
        class="mt-6 space-y-4"
      >
        <label
          for={@uploads.actors.ref}
          phx-drop-target={@uploads.actors.ref}
          class="flex cursor-pointer flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed border-base-300 p-6 text-sm transition hover:border-primary hover:bg-base-200"
        >
          <.icon name="hero-arrow-up-tray" class="size-6" />
          <span>{gettext("Drop your file here or click to select it (.txt, .csv)")}</span>
          <.live_file_input upload={@uploads.actors} class="sr-only" />
        </label>

        <div :for={entry <- @uploads.actors.entries} id={"upload-entry-#{entry.ref}"}>
          <div class="flex items-center justify-between text-sm">
            <span>{entry.client_name}</span>
            <button
              type="button"
              phx-click="cancel_upload"
              phx-value-ref={entry.ref}
              aria-label={gettext("Cancel")}
              class="opacity-60 transition hover:opacity-100"
            >
              <.icon name="hero-x-mark" class="size-4" />
            </button>
          </div>
          <progress value={entry.progress} max="100" class="w-full">{entry.progress}%</progress>
          <p :for={err <- upload_errors(@uploads.actors, entry)} class="text-sm text-error">
            {upload_error_to_string(err)}
          </p>
        </div>

        <p :for={err <- upload_errors(@uploads.actors)} class="text-sm text-error">
          {upload_error_to_string(err)}
        </p>

        <.show_market_model_choices market_choice={@market_model} />

        <button
          type="submit"
          id="actors-upload-submit"
          disabled={@uploads.actors.entries == []}
          class="btn btn-primary"
        >
          {gettext("Upload")}
        </button>
      </form>
    </div>
    """
  end

  attr :market_choice, :integer, default: 1

  def show_market_model_choices(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="flex flex-row gap-[32px]">
        <div class={[
          @market_choice == 1 && "aura",
          @market_choice != 1 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[256px]"
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
            class="card shadow-md rounded-lg p-1 w-[256px]"
            phx-click="select-model"
            phx-value-model="2"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market1.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>

        <div class={[
          @market_choice == 3 && "aura",
          @market_choice != 3 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[256px]"
            phx-click="select-model"
            phx-value-model="3"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market1.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :market, Market
  attr :period_index, :integer, default: 0

  def sim(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <CommonLive.show_sim_action_buttons>
        <.show_add_action_form actors={Market.active_actors(@market, @period_index)} />
      </CommonLive.show_sim_action_buttons>
      <CommonLive.show_periods periods={length(@market.periods)} current_period={@period_index} />
      <.show_current_period
        info={Enum.at(@market.periods, @period_index) |> Period.info()}
        actors={Market.active_actors(@market, @period_index)}
      />
    </div>
    """
  end

  attr :actors, :list

  def show_add_action_form(assigns) do
    ~H"""
    <div class="p-[16px] flex justify-center">
      <form id="one-for-all-add-action-form" phx-submit="add-action">
        <div class="flex flex-row gap-[8px]">
          <.live_component
            module={EcosimWeb.SimLive.Market.InputAutocompleteComponent}
            id="actor-input"
            actors={@actors}
          />
          <input
            id="price"
            name="price"
            type="text"
            class="input w-[64px]"
            placeholder={gettext("price")}
          />
          <button type="submit" class="btn btn-primary">{gettext("Add")}</button>
        </div>
      </form>
    </div>
    """
  end

  attr :info, :map
  attr :actors, :list

  def show_current_period(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="flex flex-row justify-around w-[640]">
        <.show_price
          price={@info.last_seller_price}
          kind="seller"
          label={gettext("Seller")}
          actors={@actors |> Enum.filter(&(&1.type == :buyer))}
        />
        <.show_price
          price={@info.last_buyer_price}
          kind="buyer"
          label={gettext("Buyer")}
          actors={
            @actors
            |> Enum.filter(&(&1.type == :seller))
          }
        />
      </div>
      <div class="divider"></div>
      <CommonLive.show_events info={@info} />
    </div>
    """
  end

  attr :kind, :string, required: true, doc: "seller or buyer, used for ids and event params"
  attr :label, :string
  attr :price, :any
  attr :actors, :list

  def show_price(assigns) do
    ~H"""
    <div class="card card-lg shadow-md w-[192px]">
      <div class="card-body items-center flex flex-col gap-[8px]">
        <div class="card-title">{@label}</div>
        <p>
          <div :if={@price != :none}>
            {@price}
          </div>
          <div :if={@price == :none}>{gettext("No price")}</div>
          <.form
            id={"accept-#{@kind}"}
            for={}
            phx-submit="accept-price"
          >
            <.input
              type="select"
              name={"actors-input-#{@kind}"}
              value=""
              id={"actors-input-#{@kind}"}
              options={@actors |> Enum.map(& &1.name)}
              disabled={@price == :none}
            />
            <button type="submit" class="btn btn-primary" disabled={@price == :none}>
              {gettext("Accept price")}
            </button>
          </.form>
        </p>
      </div>
    </div>
    """
  end

  defp preparation_example do
    "Alice, Bruno, Chloé, David, Émilie, François"
  end

  defp upload_error_to_string(:too_large), do: gettext("The file is too large.")

  defp upload_error_to_string(:not_accepted),
    do: gettext("Format not accepted (.txt or .csv only).")

  defp upload_error_to_string(:too_many_files), do: gettext("Only one file is allowed.")
  defp upload_error_to_string(_), do: gettext("Error while uploading.")
end
