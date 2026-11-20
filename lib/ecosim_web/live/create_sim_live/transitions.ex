defmodule EcosimWeb.CreateSimLive.Transitions do
  @moduledoc """
  JS transitions shared by the create-simulation steps.
  """

  alias Phoenix.LiveView.JS

  @doc """
  Slide the step in from the right. Use it as the step's `phx-mounted`.
  """
  @spec step_in() :: JS.t()
  def step_in do
    JS.transition(
      {"ease-out duration-500", "opacity-0 translate-x-8", "opacity-100 translate-x-0"},
      time: 500
    )
  end

  @doc """
  Animate the current step out, then push `event` with `value`.

  LiveView holds back the DOM patch until the hide transition finishes, so the
  next step only appears (and runs its `phx-mounted` `step_in/0`) once the old
  one is gone.
  """
  @spec go(String.t(), map()) :: JS.t()
  def go(event, value \\ %{}) do
    JS.hide(
      to: "#steps > div",
      transition:
        {"ease-in duration-300", "opacity-100 translate-x-0", "opacity-0 -translate-x-16"},
      time: 300
    )
    |> JS.push(event, value: value)
  end
end
