defmodule EcosimWeb.SimLive.MarketLive.OneForAllModeLive do
  use EcosimWeb, :live_view

  attr :uploads, :map, required: true

  def preparation_one_for_all_mode(assigns) do
    ~H"""
    <div class="flex flex-col gap-[16px]">
      <h2 class="text-lg font-bold">{gettext("Add economical actors")}</h2>

      <.show_instructions />

      <.show_file_upload_form uploads={@uploads} />
    </div>
    """
  end

  attr :uploads, :map, required: true

  def show_file_upload_form(assigns) do
    ~H"""
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

      <button
        type="submit"
        id="actors-upload-submit"
        disabled={@uploads.actors.entries == []}
        class="btn btn-primary"
      >
        {gettext("Upload")}
      </button>
    </form>
    """
  end

  def show_instructions(assigns) do
    ~H"""
    <div>
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
