defmodule PromptlyWeb.Components.ScriptInput do
  @moduledoc """
  Renders the script input component. This includes the text editor and file input element for file uploads.
  """
  use Phoenix.Component

  import PromptlyWeb.CoreComponents
  import Promptly.ScriptUtils.ScriptValidation
  import Promptly.ScriptUtils.FileProcessing

  attr :add_script_mode, :atom
  attr :script, :string, default: ""
  attr :uploaded_script, :string, default: ""
  attr :script_word_count, :integer
  attr :upload_error, :string, default: nil
  attr :upload_processing, :boolean
  attr :uploads, :map

  def element(assigns) do
    ~H"""
    <div>
      <.input_toggle mode={@add_script_mode} />
      <.textarea_form
        script={@script}
        word_count={@script_word_count}
        visible={@add_script_mode == :default}
      />
      <.file_upload_form
        uploads={@uploads}
        script={@script}
        uploaded_script={@uploaded_script}
        upload_error={@upload_error}
        upload_processing={@upload_processing}
        visible={@add_script_mode == :import}
      />
      <.proceed_button
        script={@script}
        script_word_count={@script_word_count}
        uploaded_script={@uploaded_script}
      />
    </div>
    """
  end

  defp input_toggle(assigns) do
    ~H"""
    <div class={"toggle-container mode-#{@mode}"}>
      <div class="toggle-slider"></div>
      <div class="toggle-buttons">
        <.button class={"toggle-btn #{@mode == :default && "active"}"} phx-click="default_add_mode">
          Text Area
        </.button>
        <.button class={"toggle-btn #{@mode == :import && "active"}"} phx-click="import_add_mode">
          File Import
        </.button>
      </div>
    </div>
    """
  end

  defp textarea_form(assigns) do
    ~H"""
    <div class={if @visible, do: "space-y-4", else: "space-y-4 hidden"}>
      <form phx-change="update_script" phx-debounce="300">
        <.input
          type="textarea"
          name="script"
          value={@script}
          placeholder="Enter your script here..."
          class="min-h-[200px] resize-none"
          rows="10"
          phx-hook="MaintainFocus"
          phx-mounted={Phoenix.LiveView.JS.focus()}
          id="script-textarea"
        />
      </form>
      <.script_word_counter word_count={@word_count} script={@script} />
    </div>
    """
  end

  defp file_upload_form(assigns) do
    file_upload = Map.get(assigns.uploads || %{}, :file, nil)

    assigns =
      assigns
      |> assign(file_upload: file_upload)

    ~H"""
    <div :if={@visible} class={if @visible, do: "space-y-4", else: "space-y-4 hidden"}>
      <form phx-submit="read_file" phx-change="validate">
        <div>
          <.file_upload_input
            uploads={@uploads}
            upload_processing={@upload_processing}
            upload_error={@upload_error}
            script={@script}
          />
          <.file_upload_preview
            uploads={@uploads}
            upload_error={@upload_error}
            script={@script}
          />
        </div>
        <.uploaded_script_preview script={@uploaded_script} />
      </form>
    </div>
    """
  end

  defp file_upload_input(assigns) do
    general_errors = upload_errors(assigns.uploads.file)
    entry_errors =
      assigns.uploads.file.entries
      |> Enum.flat_map(fn entry -> upload_errors(assigns.uploads.file, entry) end)

    has_errors = general_errors != [] or entry_errors != []
    has_valid_entries = assigns.uploads.file.entries != [] and entry_errors == []
    has_script_conflict = String.length(String.trim(assigns.script)) > 0 && assigns.uploads.file.entries != []

    assigns = assign(assigns,
      has_errors: has_errors,
      has_valid_entries: has_valid_entries,
      has_script_conflict: has_script_conflict
    )

    ~H"""
    <div class={[
      "border transition-colors rounded-button",
      "#{if @has_errors or @has_script_conflict,
        do: "border-red-400",
        else: "border-gray-300"}"
    ]}>
      <div class="flex flex-col sm:flex-row">
        <.live_file_input
          upload={@uploads.file}
          accept=".pdf, .txt, .docx, .doc"
          class={[
            "flex-1 block w-full text-sm text-gray-500 file:border-none file:outline-none file:rounded-tl-[8px] sm:file:rounded-tl-[8px] sm:file:rounded-bl-[8px] sm:file:rounded-tr-none sm:file:rounded-br-none file:py-2 file:mr-2",
            "#{if @has_errors or @has_script_conflict,
              do: "file:text-red-600",
              else: ""}"
          ]}
        />
        <.button
          type="submit"
          class="w-full sm:w-auto bg-primary text-white px-2 py-1 rounded-bl-[8px] rounded-tr-none rounded-br-[8px] sm:rounded-br-[8px] sm:rounded-tr-[8px] sm:rounded-tl-none sm:rounded-bl-none disabled:cursor-not-allowed transition-colors disabled:opacity-50"
          disabled={
            not @has_valid_entries or @has_errors or @upload_processing or @has_script_conflict
          }
        >
          Upload file
        </.button>
      </div>
    </div>
    """
  end

  defp file_upload_preview(assigns) do
    ~H"""
    <p class="text-xs text-gray-500 mt-1 mb-4" id="file_input_help">
      <%= if @uploads.file.entries != [] do %>
        <%= for entry <- @uploads.file.entries do %>
          <div class="mb-4 p-3 bg-gray-50 rounded-lg">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-gray-900">
                  {entry.client_name}
                </p>
                <p class="text-xs text-gray-500">
                  {Float.round(entry.client_size / 1024 / 1024, 2)} MB
                </p>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-32 bg-gray-200 rounded-full h-2">
                  <div
                    class="bg-primary h-2 rounded-full transition-all duration-300"
                    style={"width: #{entry.progress}%"}
                  >
                  </div>
                </div>
                <span class="text-xs text-gray-500">
                  {entry.progress}%
                </span>
              </div>
            </div>
            <.file_upload_errors uploads={@uploads} entry={entry} upload_error={@upload_error} />
          </div>
        <% end %>
      <% else %>
        Supported formats: PDF, TXT, DOCX (max 10MB)
      <% end %>
    </p>
    """
  end

  defp file_upload_errors(assigns) do
    ~H"""
    <.error :for={err <- upload_errors(@uploads.file, @entry)}>
      {error_to_string(err)}
    </.error>
    <.error :for={err <- upload_errors(@uploads.file)}>
      {error_to_string(err)}
    </.error>
    <.error :if={@upload_error}>
      {@upload_error}
    </.error>
    """
  end

  defp uploaded_script_preview(assigns) do
    ~H"""
    <div class="bg-gray-50 p-4 rounded-button border mb-1">
      <div class="flex items-center justify-between">
        <div class="text-sm text-gray-600 mb-2">
          Word count: {count_words(@script)}
        </div>
        <div class="-mt-3 flex items-center gap-1">
          <.button phx-click="clear_file">Clear</.button>
        </div>
      </div>
      <pre class="overflow-auto h-72 max-h-72 whitespace-pre-wrap break-words text-sm text-gray-700 leading-relaxed tracking-wide"><%= @script %></pre>
    </div>
    """
  end

  defp script_word_counter(assigns) do
    ~H"""
    <div class={"mt-2 space-y-2 border-b pb-3 #{assigns[:class]}"}>
      <div class="flex justify-between items-center text-sm">
        <span class="font-medium">Word count: {@word_count}</span>
      </div>
      <p
        :if={!valid_character_count?(@script)}
        class="text-xs text-gray-500"
      >
        Add script script to continue.
      </p>
    </div>
    """
  end

  defp proceed_button(assigns) do
    ~H"""
    <div class="mt-8 flex justify-end">
      <.button
        phx-click="next_step"
        disabled={can_proceed?(assigns) == false}
        class={
          if can_proceed?(assigns),
            do: "bg-primary p-2 text-white !rounded-button",
            else: "opacity-50 bg-primary !rounded-button p-2 text-white cursor-not-allowed"
        }
      >
        Proceed
      </.button>
    </div>
    """
  end

  defp can_proceed?(assigns) do
    trimmed_script = String.trim(assigns.script)
    assigns.uploaded_script != "" || String.length(trimmed_script) > 0
  end
end
