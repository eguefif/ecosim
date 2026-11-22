defmodule EcosimWeb.CreateSimLive.AddParticipantsComponent do
  @moduledoc """
  Step 3 of the simulation creation: add the participants.

  In one-for-all mode, participants come from an uploaded file. The parent
  LiveView must `allow_upload(:participants, ...)` and handle the
  `validate_upload`, `cancel_upload` and `save_upload` events.
  """

  use EcosimWeb, :html

  attr :mode, :string, doc: "the selected mode"
  attr :join_code, :integer
  attr :uploads, :map, required: true
  attr :participants, :list, default: []

  def add_participants(assigns) do
    ~H"""
    <.add_participants_one_for_all
      :if={@mode == "one_for_all"}
      uploads={@uploads}
      participants={@participants}
    />
    <.add_participants_multi
      :if={@mode == "multi"}
      join_code={@join_code}
      participants={@participants}
    />
    """
  end

  attr :uploads, :map, required: true
  attr :participants, :list, default: []

  def add_participants_one_for_all(assigns) do
    ~H"""
    <div class="flex flex-col gap-[16px]">
      <h2 class="text-lg font-bold">{gettext("Add economical actors")}</h2>

      <.participants_instructions />

      <div class="flex flex-row items-center gap-[16px]">
        <span class="text-sm opacity-70">{gettext("No file at hand?")}</span>
        <button
          type="button"
          id="example-participants-button"
          phx-click="use-example-participants"
          class="btn btn-secondary btn-sm"
        >
          <.icon name="hero-users" class="size-4" />
          {gettext("Use example list")}
        </button>
      </div>

      <.participants_upload_form uploads={@uploads} />

      <.participants_list :if={@participants != []} participants={@participants} />
    </div>
    """
  end

  def participants_instructions(assigns) do
    ~H"""
    <div>
      {gettext("Upload a file containing the participants' names, separated by commas.")}
      <pre id="participants-file-example" class="mt-2 rounded-lg bg-base-200 p-4 font-mono text-sm">{participants_example()}</pre>
    </div>
    """
  end

  attr :uploads, :map, required: true

  def participants_upload_form(assigns) do
    ~H"""
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
        <span>{gettext("Drop your file here or click to select it (.txt, .csv)")}</span>
        <.live_file_input upload={@uploads.participants} class="sr-only" />
      </label>

      <div :for={entry <- @uploads.participants.entries} id={"upload-entry-#{entry.ref}"}>
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
        {gettext("Upload")}
      </button>
    </form>
    """
  end

  attr :participants, :list, required: true
  attr :removable, :boolean, default: true, doc: "show a remove button on each participant"

  def participants_list(assigns) do
    ~H"""
    <div class="divider text-xl">{gettext("Actors")}</div>
    <div id="participants" class="flex flex-row flex-wrap gap-[32px]">
      <div
        :for={name <- @participants}
        class="relative flex items-center justify-center bg-info w-[128px] h-[64px] rounded-lg px-6"
      >
        <span class="text-lg font-bold truncate">{name}</span>
        <button
          :if={@removable}
          class="btn btn-square btn-ghost btn-xs absolute top-1 right-1"
          phx-click="remove-participant"
          phx-value-participant={name}
          aria-label={gettext("Remove")}
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      </div>
    </div>
    """
  end

  attr :join_code, :integer, required: true
  attr :participants, :list, default: []

  def add_participants_multi(assigns) do
    ~H"""
    <div class="flex flex-col gap-[16px]">
      <h2 class="text-lg font-bold">{gettext("Wait for participants to connect")}</h2>
      <div class="shadow-md rounded-lg mx-auto w-[192px] flex flex-col justify-center items-center p-[32px] gap-[32px]">
        <div class="text-xl">{gettext("Code")}</div>
        <div class="text-5xl">{@join_code}</div>
      </div>

      <.participants_list :if={@participants != []} participants={@participants} removable={false} />
      <p
        :if={@participants == []}
        id="participants-waiting"
        class="flex items-center justify-center gap-2 text-sm opacity-70"
      >
        <span class="loading loading-dots loading-sm"></span>
        {gettext("No participant has joined yet")}
      </p>
    </div>
    """
  end

  @doc """
  The example participants list, shown in the instructions and loaded by the
  "Use example list" button.
  """
  @spec example_participants() :: [String.t()]
  def example_participants, do: ["Alice", "Bruno", "Chloé", "David", "Émilie", "François"]

  defp participants_example, do: Enum.join(example_participants(), ", ")

  defp upload_error_to_string(:too_large), do: gettext("The file is too large.")

  defp upload_error_to_string(:not_accepted),
    do: gettext("Format not accepted (.txt or .csv only).")

  defp upload_error_to_string(:too_many_files), do: gettext("Only one file is allowed.")
  defp upload_error_to_string(_), do: gettext("Error while uploading.")
end
