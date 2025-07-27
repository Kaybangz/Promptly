defmodule PromptlyWeb.Components.ScriptInput do
  @moduledoc """
  A dual-mode script input component that allows users to either type their
  script directly in a rich text editor or upload it from supported file
  formats.
  """
  use Phoenix.Component

  import PromptlyWeb.CoreComponents

  import PromptlyWeb.Live.Utils.FileProcessing
  import PromptlyWeb.Live.Utils.ScriptValidation

  attr :script_input_mode, :atom
  attr :script, :string, default: ""
  attr :script_form, :map, default: %{}
  attr :uploaded_script, :string, default: ""
  attr :word_count, :integer
  attr :upload_error, :string, default: nil
  attr :upload_processing, :boolean
  attr :uploads, :map

  def element(assigns) do
    ~H"""
    <div>
      <.input_toggle mode={@script_input_mode} />
      <.text_editor
        script_form={@script_form}
        script={@script}
        word_count={@word_count}
        visible={@script_input_mode == :default}
      />
      <.file_upload_form
        uploads={@uploads}
        script={@script}
        uploaded_script={@uploaded_script}
        upload_error={@upload_error}
        upload_processing={@upload_processing}
        visible={@script_input_mode == :import}
      />
      <.proceed_button {assigns} />
    </div>
    """
  end

  defp input_toggle(assigns) do
    ~H"""
    <div class={"toggle-container mode-#{@mode}"}>
      <div class="toggle-slider"></div>
      <div class="toggle-buttons">
        <.button
          class={"toggle-btn #{@mode == :default && "active"}"}
          phx-click="toggle_script_input_mode"
          phx-value-mode="default"
        >
          Text Editor
        </.button>
        <.button
          class={"toggle-btn #{@mode == :import && "active"}"}
          phx-click="toggle_script_input_mode"
          phx-value-mode="import"
        >
          File Import
        </.button>
      </div>
    </div>
    """
  end

  defp text_editor(assigns) do
    ~H"""
    <div class={if @visible, do: "space-y-4", else: "space-y-4 hidden"}>
      <.simple_form
        for={@script_form}
        id="editor-form"
        phx-change="update_script"
        phx-debounce="300"
        class="mb-8 relative"
      >
        <.input
          field={@script_form[:content]}
          id="editor-content"
          type="hidden"
          phx-hook="Trix"
          value={@script}
          class="min-h-[200px] resize-none"
        />
        <div id="trix-editor-container" phx-update="ignore" class="mb-4">
          <trix-editor input="editor-content" class="border rounded-button trix-editor-fixed-height">
          </trix-editor>
        </div>
        <.word_counter word_count={@word_count} script={@script} />
      </.simple_form>
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
          <.file_upload_preview uploads={@uploads} upload_error={@upload_error} script={@script} />
        </div>
        <.uploaded_script_preview script={@uploaded_script} />
      </form>
    </div>
    """
  end

  defp file_upload_input(assigns) do
    upload_state = analyze_upload_state(assigns)
    assigns = assign(assigns, upload_state)

    ~H"""
    <div class={upload_container_classes(@has_errors, @has_script_conflict)}>
      <div class="flex flex-col sm:flex-row">
        <.live_file_input
          upload={@uploads.file}
          accept=".pdf, .txt, .docx, .doc"
          class={file_input_classes(@has_errors, @has_script_conflict)}
        />
        <.button
          type="submit"
          class={upload_button_classes()}
          disabled={
            upload_disabled?(
              @has_valid_entries,
              @has_errors,
              @upload_processing,
              @has_script_conflict
            )
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
    <div class="text-xs text-gray-500 mt-1 mb-4" id="file_input_help">
      <%= if has_file_entries?(@uploads.file) do %>
        <div class="space-y-4">
          <.file_entry
            :for={entry <- @uploads.file.entries}
            entry={entry}
            uploads={@uploads}
            upload_error={@upload_error}
          />
        </div>
      <% else %>
        <p>Supported formats: PDF, TXT, DOCX (max 10MB)</p>
      <% end %>
    </div>
    """
  end

  defp file_entry(assigns) do
    ~H"""
    <div class="p-3 bg-gray-50 rounded-lg">
      <div class="flex items-center justify-between">
        <.file_info entry={@entry} />
        <.progress_bar entry={@entry} />
      </div>
      <.file_upload_errors uploads={@uploads} entry={@entry} upload_error={@upload_error} />
    </div>
    """
  end

  defp file_info(assigns) do
    ~H"""
    <div>
      <p class="text-sm font-medium text-gray-900">
        {@entry.client_name}
      </p>
      <p class="text-xs text-gray-500">
        {format_file_size(@entry.client_size)} MB
      </p>
    </div>
    """
  end

  defp progress_bar(assigns) do
    ~H"""
    <div class="flex items-center space-x-2">
      <div class="w-32 bg-gray-200 rounded-full h-2">
        <div
          class="bg-primary h-2 rounded-full transition-all duration-300"
          style={"width: #{@entry.progress}%"}
        >
        </div>
      </div>
      <span class="text-xs text-gray-500">
        {@entry.progress}%
      </span>
    </div>
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
          <.button type="button" phx-click="clear_file">Clear</.button>
        </div>
      </div>
      <pre class="overflow-auto h-72 max-h-72 whitespace-pre-wrap break-words text-sm text-gray-700 leading-relaxed tracking-wide"><%= @script %></pre>
    </div>
    """
  end

  defp word_counter(assigns) do
    ~H"""
    <div class="absolute bottom-2 right-5 bg-white bg-opacity-90 border border-gray-200 rounded px-2 py-1 text-xs text-gray-600 pointer-events-none shadow-sm">
      <div class="flex items-center gap-1">
        <span class="font-medium">Words: {@word_count}</span>
      </div>
      <p :if={count_words(@script) <= 0} class="text-xs text-blue-500 mt-1">
        Please enter or upload script to proceed.
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

  defp analyze_upload_state(assigns) do
    file_upload = assigns.uploads.file
    general_errors = upload_errors(file_upload)
    entry_errors = Enum.flat_map(file_upload.entries, &upload_errors(file_upload, &1))

    has_errors = general_errors != [] or entry_errors != []
    has_valid_entries = file_upload.entries != [] and entry_errors == []
    has_script_conflict = script_exists?(assigns.script) and file_upload.entries != []

    %{
      has_errors: has_errors,
      has_valid_entries: has_valid_entries,
      has_script_conflict: has_script_conflict
    }
  end

  defp script_exists?(script) do
    String.length(String.trim(script)) > 0
  end

  defp upload_container_classes(has_errors, has_script_conflict) do
    base_classes = "border transition-colors rounded-button"

    error_classes =
      if has_errors or has_script_conflict, do: "border-red-400", else: "border-gray-300"

    [base_classes, error_classes]
  end

  defp file_input_classes(has_errors, has_script_conflict) do
    base_classes =
      "flex-1 block w-full text-sm text-gray-500 file:border-none file:outline-none file:rounded-tl-[8px] sm:file:rounded-tl-[8px] sm:file:rounded-bl-[8px] sm:file:rounded-tr-none sm:file:rounded-br-none file:py-2 file:mr-2"

    error_classes = if has_errors or has_script_conflict, do: "file:text-red-600", else: ""
    [base_classes, error_classes]
  end

  defp upload_button_classes do
    "w-full sm:w-auto bg-primary text-white px-2 py-1 rounded-bl-[8px] rounded-tr-none rounded-br-[8px] sm:rounded-br-[8px] sm:rounded-tr-[8px] sm:rounded-tl-none sm:rounded-bl-none disabled:cursor-not-allowed transition-colors disabled:opacity-50"
  end

  defp upload_disabled?(has_valid_entries, has_errors, upload_processing, has_script_conflict) do
    not has_valid_entries or has_errors or upload_processing or has_script_conflict
  end

  defp has_file_entries?(file_upload) do
    file_upload.entries != []
  end

  defp format_file_size(size_bytes) do
    Float.round(size_bytes / 1024 / 1024, 2)
  end

  defp can_proceed?(assigns) do
    assigns.uploaded_script != "" || count_words(assigns.script) > 0
  end
end
