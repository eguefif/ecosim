defmodule EcosimWeb.SimLive.Market.InputAutocompleteComponent do
  use Phoenix.LiveComponent
  use Gettext, backend: EcosimWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <input
        id="actor-input"
        name="actor-input"
        type="text"
        class="input w-[196px]"
        placeholder={gettext("actor")}
        phx-change="user-change-input"
        phx-target={@myself}
        value={@selected_value}
      />
      <input type="hidden" value={@selected_value} name="actor" />
      <div :if={@show_entries == true} class="static">
        <ul
          class="list bg-base-200 shadow-md w-[196px] absolute z-10 isolate"
          phx-click-away="click-away"
          phx-target={@myself}
        >
          <li
            :for={entry <- @entries}
            class="list-row hover:bg-base-300"
            phx-click="select-entry"
            phx-value-entry={entry}
            phx-target={@myself}
          >
            {entry}
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:show_entries, false)
     |> assign(:entries, [])
     |> assign(:selected_value, nil)}
  end

  @impl true
  def handle_event("user-change-input", %{"actor-input" => value}, socket) do
    entries =
      socket.assigns.actors
      |> Enum.map(& &1.name)
      |> Enum.map(&{String.jaro_distance(&1, value), &1})
      |> Enum.sort(fn {jaro1, _}, {jaro2, _} ->
        jaro1 > jaro2
      end)
      |> Enum.map(&elem(&1, 1))

    {:noreply, socket |> assign(:show_entries, true) |> assign(:entries, entries)}
  end

  @impl true
  def handle_event("select-entry", %{"entry" => value}, socket) do
    {:noreply,
     socket
     |> assign(:selected_value, value)
     |> assign(:show_entries, false)
     |> assign(:entries, [])}
  end

  @impl true
  def handle_event("click-away", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_value, nil)
     |> assign(:show_entries, false)
     |> assign(:entries, [])}
  end
end
