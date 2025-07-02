defmodule PromptlyWeb.Components.ScriptInput do
  use Phoenix.Component

  import PromptlyWeb.CoreComponents
  import Promptly.ScriptUtils.ScriptValidation
  import Promptly.ScriptUtils.FileProcessing

  @doc """
  Renders a complete script input form with toggle, text area, file upload, and proceed button.
  """
  attr :add_script_mode, :atom
  attr :script, :string, default: ""
  attr :uploaded_script, :string, default: ""
  attr :script_word_count, :integer
  attr :script_upload_error, :string, default: nil
  attr :uploads, :map, required: false

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
        uploaded_script={@uploaded_script}
        script_upload_error={@script_upload_error}
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
        <.button
          class={"toggle-btn #{@mode == :default && "active"}"}
          phx-click="default_add_mode"
        >
          Text Area
        </.button>
        <.button
          class={"toggle-btn #{@mode == :import && "active"}"}
          phx-click="import_add_mode"
        >
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
          errors={
            if !valid_script?(@word_count),
              do: ["Exceeded maximum word count. Reduce number of words in your script."],
              else: []
          }
        />
      </form>
      <.script_word_counter word_count={@word_count} script={@script} show_error_message={true} />
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
          <.file_upload_input uploads={@uploads} />
          <.file_upload_preview uploads={@uploads} />
          <.file_upload_errors uploads={@uploads} script_upload_error={@script_upload_error} />
        </div>
        <.uploaded_script_preview script={@uploaded_script} />
        <div class="mt-2 space-y-2 border-b pb-3">
          <.error :if={!valid_script?(count_words(@uploaded_script))}>
            Exceeded maximum word count. Reduce number of words in your script.
          </.error>
        </div>
      </form>
    </div>
    """
  end

  defp file_upload_input(assigns) do
    ~H"""
    <div class={[
      "border transition-colors rounded-button",
      "#{if upload_errors(@uploads.file) != [],
        do: "border-red-400",
        else: "border-gray-300"}"
    ]}>
      <div class="flex flex-col sm:flex-row">
        <.live_file_input
          upload={@uploads.file}
          accept=".pdf, .txt, .docx, .doc"
          class={[
            "flex-1 block w-full text-sm text-gray-500 file:border-none file:outline-none file:rounded-tl-[8px] sm:file:rounded-tl-[8px] sm:file:rounded-bl-[8px] sm:file:rounded-tr-none sm:file:rounded-br-none file:py-2 file:mr-2",
            "#{if upload_errors(@uploads.file) != [],
              do: "file:text-red-600",
              else: ""}"
          ]}
        />
        <.button
          type="submit"
          class="w-full sm:w-auto bg-primary text-white px-2 py-1 rounded-bl-[8px] rounded-tr-none rounded-br-[8px] sm:rounded-br-[8px] sm:rounded-tr-[8px] sm:rounded-tl-none sm:rounded-bl-none disabled:cursor-not-allowed transition-colors disabled:opacity-50"
          disabled={@uploads.file.entries == [] or upload_errors(@uploads.file) != []}
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
          SELECTED FILE: {entry.client_name} ({entry.client_size} bytes)
        <% end %>
      <% else %>
        TXT, PDF, DOCX, or DOC up to 10MB
      <% end %>
    </p>
    """
  end

  defp file_upload_errors(assigns) do
    ~H"""
    <div class="mb-4">
      <.error :for={err <- upload_errors(@uploads.file)}>
        {upload_error_to_string(err)}
      </.error>
      <.error :if={@script_upload_error && @uploads.file.entries != []}>
        {@script_upload_error}
      </.error>
    </div>
    """
  end

  defp uploaded_script_preview(assigns) do
    ~H"""
    <div class="bg-gray-50 p-4 rounded-button border mb-1">
      <div class="flex items-center justify-between">
        <div class={[
          "text-sm text-gray-600 mb-2",
          !valid_script?(count_words(@script)) && "text-red-600"
        ]}>
          Word count: {count_words(@script)} / {max_number_of_words()}
        </div>
        <div class="-mt-3 flex items-center gap-1">
          <.button phx-click="clear_file">Clear</.button>
        </div>
      </div>
      <pre class="overflow-auto h-72 max-h-72 whitespace-pre-wrap text-sm text-gray-700"><%= @script %></pre>
    </div>
    """
  end

  defp script_word_counter(assigns) do
    assigns = assign(assigns, is_valid: valid_script?(assigns.word_count))

    ~H"""
    <div class={"mt-2 space-y-2 border-b pb-3 #{assigns[:class]}"}>
      <div class="flex justify-between items-center text-sm">
        <span class={[
          "font-medium",
          !@is_valid && "text-red-600"
        ]}>
          Word count: {@word_count} / {max_number_of_words()}
        </span>
      </div>
      <p
        :if={assigns[:show_error_message] && !valid_character_count?(@script)}
        class="text-xs text-gray-500"
      >
        Please enter or upload your script to continue.
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
    assigns.uploaded_script != "" || assigns.script != ""
  end
end
