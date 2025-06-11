defmodule PromptlyWeb.TeleprompterLive do
  use PromptlyWeb, :live_view

  alias PromptlyWeb.Components.ScriptInput
  alias PromptlyWeb.Components.Settings

  import Promptly.ScriptUtils.FileProcessing
  import Promptly.ScriptUtils.ScriptValidation

  @total_steps 2

  @default_settings %{
    mode: :manual,
    speed: 1.0,
    font_size: 36,
    font_family: %{
      family: "Arial, sans-serif",
      name: "Arial",
      dropdown_open: false
    },
    theme: :light,
    mirror_mode: false,
    preview_scroll_key: :os.system_time(:millisecond)
  }

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(
      script: "",
      uploaded_script: "",
      script_upload_error: nil,
      add_script_mode: :default,
      script_word_count: 0,
      current_step: 1,
      total_steps: @total_steps,
      settings: @default_settings
    )
    |> allow_upload(
      :file,
      accept: ~w(.txt .pdf .docx .doc),
      max_entries: 1,
      max_file_size: 10_000_000
    )
    |> ok()
  end

  @impl true
  def handle_event("default_add_mode", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.file.entries, socket, fn entry, acc ->
        cancel_upload(acc, :file, entry.ref)
      end)

    socket
    |> assign(add_script_mode: :default)
    |> assign(uploaded_script: "")
    |> assign(script_upload_error: nil)
    |> noreply()
  end

  @impl true
  def handle_event("import_add_mode", _params, socket) do
    socket
    |> assign(add_script_mode: :import)
    |> noreply()
  end

  @impl true
  def handle_event("update_script", %{"script" => script}, socket) do
    word_count = count_words(script)

    socket
    |> assign(script: script)
    |> assign(script_word_count: word_count)
    |> noreply()
  end

  @impl true
  def handle_event("validate", _params, socket) do
    noreply(socket)
  end

  @impl true
  def handle_event("read_file", _params, socket) do
    if socket.assigns.script != "" && socket.assigns.script_word_count > 0 do
      socket
      |> assign(
        script_upload_error:
          "Please clear the text area before uploading a file. You cannot have both text area content and an uploaded file."
      )
      |> noreply()
    else
      socket = assign(socket, script_upload_error: nil)

      uploaded_files =
        consume_uploaded_entries(socket, :file, fn %{path: path}, _ ->
          case File.read(path) do
            {:ok, content} -> content
            {:error, reason} -> {:error, reason}
          end
        end)

      case uploaded_files do
        [content] when is_binary(content) ->
          processed_content = process_content(content)

          socket
          |> assign(uploaded_script: processed_content)
          |> assign(script_upload_error: nil)
          |> noreply()

        [{:error, reason}] ->
          socket
          |> assign(script_upload_error: "Failed to read file: #{reason}")
          |> noreply()

        [] ->
          socket
          |> assign(script_upload_error: "No file uploaded - please select a file first")
          |> noreply()

        _ ->
          socket
          |> assign(script_upload_error: "Unexpected error processing file")
          |> noreply()
      end
    end
  end

  @impl true
  def handle_event("clear_file", _params, socket) do
    socket
    |> assign(uploaded_script: "")
    |> noreply()
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    if socket.assigns.current_step == 1 do
      socket
      |> assign(current_step: socket.assigns.current_step + 1)
      |> noreply()
    else
      noreply(socket)
    end
  end

  @impl true
  def handle_event("previous_step", _params, socket) do
    if socket.assigns.current_step > 1 do
      socket
      |> assign(current_step: socket.assigns.current_step - 1)
      |> noreply()
    else
      noreply(socket)
    end
  end

  @impl true
  def handle_event("toggle_font_family_dropdown", _params, socket) do
    current = socket.assigns.settings.font_family.dropdown_open
    font_family = %{socket.assigns.settings.font_family | dropdown_open: !current}
    updated_settings = %{socket.assigns.settings | font_family: font_family}

    socket
    |> assign(settings: updated_settings)
    |> noreply()
  end

  @impl true
  def handle_event("close_font_family_dropdown", _params, socket) do
    font_family = %{socket.assigns.settings.font_family | dropdown_open: false}
    updated_settings = %{socket.assigns.settings | font_family: font_family}

    socket
    |> assign(settings: updated_settings)
    |> noreply()
  end

  @impl true
  def handle_event("update_mode", %{"mode" => mode}, socket) do
    mode = String.to_atom(mode)
    updated_settings = %{socket.assigns.settings | mode: mode}

    socket
    |> assign(settings: updated_settings)
    |> noreply()
  end

  @impl true
  def handle_event("update_font_family", %{"family" => family, "name" => name}, socket) do
    font_family = %{family: family, name: name, dropdown_open: false}
    updated_settings = %{socket.assigns.settings | font_family: font_family}

    socket
    |> assign(settings: updated_settings)
    |> restart_animation()
    |> noreply()
  end

  @impl true
  def handle_event("update_speed", %{"speed" => speed}, socket) do
    speed = String.to_float(speed)
    updated_settings = %{socket.assigns.settings | speed: speed}

    socket
    |> assign(settings: updated_settings)
    |> restart_animation()
    |> noreply()
  end

  @impl true
  def handle_event("update_font_size", %{"font-size" => font_size}, socket) do
    font_size = String.to_integer(font_size)
    updated_settings = %{socket.assigns.settings | font_size: font_size}

    socket
    |> assign(settings: updated_settings)
    |> restart_animation()
    |> noreply()
  end

  @impl true
  def handle_event("update_theme", %{"theme" => theme}, socket) do
    theme = String.to_atom(theme)
    updated_settings = %{socket.assigns.settings | theme: theme}

    socket
    |> assign(settings: updated_settings)
    |> noreply()
  end

  def handle_event("update_mirror_mode", _params, socket) do
    updated_settings = %{socket.assigns.settings | mirror_mode: !socket.assigns.settings.mirror_mode}

    socket
    |> assign(settings: updated_settings)
    |> restart_animation()
    |> noreply()
  end

  @impl true
  def handle_event("reset_settings", _params, socket) do
    socket
    |> assign(settings: @default_settings)
    |> restart_animation()
    |> noreply()
  end

  defp restart_animation(socket) do
    socket
    |> assign(:settings, %{socket.assigns.settings | preview_scroll_key: :os.system_time(:millisecond)})
  end
end
