defmodule PromptlyWeb.TeleprompterLive do
  use PromptlyWeb, :live_view

  alias PromptlyWeb.Components.Header
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
      css: "Arial, sans-serif",
      display_name: "Arial",
      dropdown_open: false
    },
    theme: :light,
    mirror_mode: false,
    countdown_timer: 3,
    preview_scroll_key: :os.system_time(:millisecond)
  }

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(
      script: "",
      uploaded_script: "",
      upload_error: nil,
      upload_processing: false,
      add_script_mode: :default,
      script_word_count: 0,
      current_step: 1,
      total_steps: @total_steps,
      settings: @default_settings
    )
    |> allow_upload(
      :file,
      accept: ~w(.txt .pdf .docx),
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
    |> assign(upload_error: nil)
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
    upload_error =
      if String.length(String.trim(socket.assigns.script)) > 0 &&
           socket.assigns.uploads.file.entries != [] do
        "Please clear the text area before uploading a file. You cannot have both text area content and an uploaded file."
      else
        nil
      end

    socket
    |> assign(upload_error: upload_error)
    |> noreply()
  end

  @impl true
  def handle_event("read_file", _params, socket) do
    socket =
      socket
      |> assign(upload_error: nil)
      |> assign(upload_processing: true)
      |> assign(uploaded_script: "")

    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        dest =
          Path.join(System.tmp_dir(), "#{entry.uuid}.#{get_file_extension(entry.client_name)}")

        File.cp!(path, dest)
        {:ok, %{path: dest, name: entry.client_name, type: get_file_type(entry.client_name)}}
      end)

    case uploaded_files do
      [file] ->
        case extract_text_from_file(file) do
          {:ok, text} ->
            File.rm(file.path)

            socket
            |> assign(uploaded_script: text)
            |> assign(upload_processing: false)
            |> noreply()

          {:error, reason} ->
            File.rm(file.path)

            socket
            |> assign(upload_error: "Error processing text: #{reason}")
            |> assign(upload_processing: false)
            |> noreply()
        end

      [] ->
        socket
        |> assign(upload_error: "No file uploaded.")
        |> assign(processing: false)
        |> noreply()
    end
  end

  @impl true
  def handle_event("clear_file", _params, socket) do
    socket
    |> assign(uploaded_script: "")
    |> assign(upload_error: nil)
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
  def handle_event("update_font_family", %{"css" => css, "display_name" => display_name}, socket) do
    font_family = %{css: css, display_name: display_name, dropdown_open: false}
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
    updated_settings = %{
      socket.assigns.settings
      | mirror_mode: !socket.assigns.settings.mirror_mode
    }

    socket
    |> assign(settings: updated_settings)
    |> restart_animation()
    |> noreply()
  end

  @impl true
  def handle_event("update_countdown_timer", %{"action" => "increment"}, socket) do
    current_value = socket.assigns.settings.countdown_timer
    new_value = min(current_value + 1, 60)
    updated_settings = %{socket.assigns.settings | countdown_timer: new_value}

    socket
    |> assign(settings: updated_settings)
    |> noreply()
  end

  @impl true
  def handle_event("update_countdown_timer", %{"action" => "decrement"}, socket) do
    current_value = socket.assigns.settings.countdown_timer
    new_value = max(current_value - 1, 0)
    updated_settings = %{socket.assigns.settings | countdown_timer: new_value}

    socket
    |> assign(settings: updated_settings)
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
    |> assign(:settings, %{
      socket.assigns.settings
      | preview_scroll_key: :os.system_time(:millisecond)
    })
  end
end
