defmodule EcosimWeb.SimLive.OneForAllModeLive do
  use EcosimWeb, :live_view

  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Period

  attr :mode, :string
  attr :uploads, :map, required: true
  attr :participants, :list

  def preparation(assigns) do
    ~H"""
    <div class="flex flex-col gap-[8px]">
      <.preparation_one_for_all_mode :if={@mode == "one-for-all"} uploads={@uploads} />

      <.show_participants :if={@participants != []} participants={@participants} />
      <div class="divider"></div>
      <div
        class={["btn btn-primary w-[96px] mx-auto", @participants == [] && "btn-disabled"]}
        phx-click="start"
      >
        Démarrer
      </div>
    </div>
    """
  end

  attr :participants, :list, required: true

  def show_participants(assigns) do
    # Use market lists to display users
    ~H"""
    <div class="divider text-xl">Participants</div>
    <ul id="participants" class="list gap-[4px]">
      <li
        :for={[type, name, _] <- @participants}
        class={[
          type == "acheteur" && "bg-buyer",
          type == "vendeur" && "bg-seller",
          "list-row items-baseline flex flex-row justify-between"
        ]}
      >
        <div class="flex flex-row gap-[16px] items-baseline">
          <span class="text-lg font-bold">{name}</span><span class="italic">{get_type(type)}</span>
        </div>
        <button class="btn btn-square btn-ghost">
          <.icon name="hero-x-mark" />
        </button>
      </li>
    </ul>
    """
  end

  def get_type("vendeur"), do: "Vendeur"
  def get_type("acheteur"), do: "Acheteur"

  attr :uploads, :map, required: true

  def preparation_one_for_all_mode(assigns) do
    ~H"""
    <div>
      Ce mode requiert de la préparation. Chacun de vos utilisateurs doivent savoir leur rôle et leur consentement à payer ou recevoir (CAP, CAR). Veuillez fournir un fichier texte ou csv qui se présente de la forme:<br />
      <pre id="preparation-file-example" class="mt-2 rounded-lg bg-base-200 p-4 font-mono text-sm">vendeur, Alice, 12
    vendeur, Bruno, 15
    vendeur, Chloé, 20
    acheteur, David, 25
    acheteur, Émilie, 18
    acheteur, François, 10</pre>
      <ul class="mt-2 text-sm">
        <li>
          <strong>vendeur, nom, CAR</strong> : CAR = consentement à recevoir (prix minimum accepté)
        </li>
        <li>
          <strong>acheteur, nom, CAP</strong> : CAP = consentement à payer (prix maximum accepté)
        </li>
      </ul>

      <form
        id="participants-upload-form"
        phx-change="validate_upload"
        phx-submit="save_upload"
        class="mt-6 space-y-4"
      >
        <label
          for={@uploads.participants.ref}
          phx-drop-target={@uploads.participants.ref}
          class="flex cursor-pointer flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed border-base-300 p-6 text-sm transition hover:border-primary hover:bg-base-200"
        >
          <.icon name="hero-arrow-up-tray" class="size-6" />
          <span>Glissez votre fichier ici ou cliquez pour le sélectionner (.txt, .csv)</span>
          <.live_file_input upload={@uploads.participants} class="sr-only" />
        </label>

        <div :for={entry <- @uploads.participants.entries} id={"upload-entry-#{entry.ref}"}>
          <div class="flex items-center justify-between text-sm">
            <span>{entry.client_name}</span>
            <button
              type="button"
              phx-click="cancel_upload"
              phx-value-ref={entry.ref}
              aria-label="Annuler"
              class="opacity-60 transition hover:opacity-100"
            >
              <.icon name="hero-x-mark" class="size-4" />
            </button>
          </div>
          <progress value={entry.progress} max="100" class="w-full">{entry.progress}%</progress>
          <p :for={err <- upload_errors(@uploads.participants, entry)} class="text-sm text-error">
            {upload_error_to_string(err)}
          </p>
        </div>

        <p :for={err <- upload_errors(@uploads.participants)} class="text-sm text-error">
          {upload_error_to_string(err)}
        </p>

        <button
          type="submit"
          id="participants-upload-submit"
          disabled={@uploads.participants.entries == []}
          class="btn btn-primary"
        >
          Téléverser
        </button>
      </form>
    </div>
    """
  end

  attr :market, Market
  attr :period_index, :integer, default: 0

  def sim(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="flex flex-row gap-[16px] self-center">
        <div class="btn btn-primary" phx-click="back-to-preparation">Retour</div>
        <div class="btn btn-warning" phx-click="restart-sim">Recommencer</div>
        <div class="btn btn-primary" phx-click="finish-sim">Finir</div>
        <div class="btn btn-warning" phx-click="undo-last-action">Annuler</div>
      </div>
      <.show_periods periods={length(@market.periods)} />
      <.show_add_action_form participants={Market.active_actors(@market)} />
      <.show_current_period
        info={Enum.at(@market.periods, @period_index) |> Period.info()}
        participants={@market.buyers ++ @market.sellers}
      />
    </div>
    """
  end

  attr :participants, :list

  def show_add_action_form(assigns) do
    ~H"""
    <div class="shadow-md p-[16px] flex justify-center">
      <form id="one-for-all-add-action-form" phx-submit="add-action">
        <div class="flex flex-row gap-[8px]">
          <.live_component
            module={EcosimWeb.SimLive.Market.InputAutocompleteComponent}
            id="participant-input"
            participants={@participants}
          />
          <input id="price" name="price" type="text" class="input w-[64px]" placeholder="prix" />
          <button type="submit" class="btn btn-primary">Ajouter</button>
        </div>
      </form>
    </div>
    """
  end

  attr :periods, :integer

  def show_periods(assigns) do
    ~H"""
    <div class="flex flex-row gap-[8px]">
      <.button phx-click="add-period"><.icon name="hero-plus" class="size-5" /></.button>
      <div
        :for={n <- 0..(@periods - 1)}
        class="btn btn-info"
        phx-click="show-period"
        phx-value-period={n}
      >
        Période {n + 1}
      </div>
    </div>
    """
  end

  attr :info, :map
  attr :participants, :list

  def show_current_period(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="flex flex-row justify-around w-[640]">
        <.show_price
          price={@info.last_seller_price}
          label="Vendeur"
          participants={@participants |> Enum.filter(&(&1.type == :buyer))}
        />
        <.show_price
          price={@info.last_buyer_price}
          label="Acheteur"
          participants={
            @participants
            |> Enum.filter(&(&1.type == :seller))
          }
        />
      </div>
      <div class="divider"></div>
      <div class="flex flex-row gap-[64px] justify-between w-[640]">
        <.show_transactions info={@info} />
        <div class="divider divider-horizontal"></div>
        <.show_all_actions info={@info} />
      </div>
    </div>
    """
  end

  defp action_to_string(:sell_at), do: "vend"
  defp action_to_string(:buy_at), do: "achète"

  attr :label, :string
  attr :price, :any
  attr :participants, :list

  def show_price(assigns) do
    ~H"""
    <div class="card card-lg shadow-md w-[192px]">
      <div class="card-body items-center flex flex-col gap-[8px]">
        <div class="card-title">{@label}</div>
        <p>
          <div :if={@price != :none}>
            {@price}
          </div>
          <div :if={@price == :none}>Pas de prix</div>
          <.form
            id={"accept-#{@label}"}
            for={}
            phx-submit="accept-price"
          >
            <.input
              type="select"
              name={"participants-input-#{@label |> String.downcase()}"}
              value=""
              id={"participants-input-#{@label}"}
              options={@participants |> Enum.map(& &1.name)}
              disabled={@price == :none}
            />
            <button type="submit" class="btn btn-primary" disabled={@price == :none}>Accepter prix</button>
          </.form>
        </p>
      </div>
    </div>
    """
  end

  attr :info, :map

  def show_transactions(assigns) do
    ~H"""
    <.show_actions
      actions={@info.transactions |> Enum.reverse()}
      label="Transactions"
      row_item={
        fn action ->
          actors = Map.get(action.params, :actors)
          price = Map.get(action.params, :price)
          [Enum.at(actors, 0), Enum.at(actors, 1), price]
        end
      }
    >
      <:action_row :let={[actor1, actor2, price]}>
        <div class="shadow-md p-[16px] rounded-lg text-center bg-transaction" ,>
          <span class="font-bold">{actor1.name}</span>
          vend à <span class="font-bold">{actor2.name}</span>
          aux prix de <span class="font-bold">{price}</span>
        </div>
      </:action_row>
    </.show_actions>
    """
  end

  attr :info, :map

  def show_all_actions(assigns) do
    ~H"""
    <.show_actions
      actions={@info.events |> Enum.reverse()}
      label="Événements"
      row_item={
        fn action ->
          if action.action == :transact do
            actor1 = Map.get(action.params, :actors) |> Enum.at(0)
            actor2 = Map.get(action.params, :actors) |> Enum.at(1)
            price = Map.get(action.params, :price)
            [Enum.join([actor1.name, actor2.name], " et "), :transact, price]
          else
            actor = Map.get(action.params, :actor)
            price = Map.get(action.params, :price)
            [actor, action.action, price]
          end
        end
      }
    >
      <:action_row :let={[actor, action_type, price]}>
        <div
          :if={action_type == :transact}
          class={[
            "shadow-md p-[16px] rounded-lg text-center",
            "bg-transaction"
          ]}
        >
          Transaction entre <span class="font-bold">{actor}</span>
          à <span class="font-bold">{price}</span>
        </div>
        <div
          :if={action_type != :transact}
          class={[
            "shadow-md p-[16px] rounded-lg text-center",
            action_type == :sell_at && "bg-seller",
            action_type == :buy_at && "bg-buyer"
          ]}
        >
          <span class="font-bold">{actor.name}</span> {action_to_string(action_type)} à
          <span class="font-bold">{price}</span>
        </div>
      </:action_row>
    </.show_actions>
    """
  end

  attr :label, :string
  attr :actions, :list
  slot :action_row

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row"

  def show_actions(assigns) do
    ~H"""
    <div class="flex flex-col w-full items-center">
      <div class="text-lg font-bold">{@label}</div>
      <div class="divider"></div>
      <div class="flex flex-col gap-[8px]">
        <div :for={action <- @actions}>
          {render_slot(@action_row, @row_item.(action))}
        </div>
      </div>
    </div>
    """
  end

  def result(assigns) do
    ~H"""
    <div>Result</div>
    """
  end

  defp upload_error_to_string(:too_large), do: "Le fichier est trop volumineux."
  defp upload_error_to_string(:not_accepted), do: "Format non accepté (.txt ou .csv seulement)."
  defp upload_error_to_string(:too_many_files), do: "Un seul fichier est permis."
  defp upload_error_to_string(_), do: "Erreur lors du téléversement."
end
