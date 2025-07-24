defmodule PromptlyWeb.TeleprompterLive do
  use PromptlyWeb, :live_view

  alias PromptlyWeb.Components.Header
  alias PromptlyWeb.Components.ScriptUpload
  alias PromptlyWeb.Components.TeleprompterSettings
  alias PromptlyWeb.Components.TeleprompterDisplay

  import Promptly.Utils.FileProcessing
  import Promptly.Utils.ScriptValidation
  import Promptly.Utils.Teleprompter

  @default_settings %{
    mode: :manual,
    speed: 0.8,
    font_size: 36,
    font_family: "Arial, sans-serif",
    theme: :light,
    mirror_mode: false,
    countdown_timer: 3,
    preview_scroll_key: :os.system_time(:millisecond)
  }

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(
      script_mode: :default,
      script: "",
      script_form: to_form(%{}, as: :editor),
      uploaded_script: "",
      upload_error: nil,
      upload_processing: false,
      word_count: 0,
      current_step: 1,
      total_steps: 2,
      settings: @default_settings,
      show_teleprompter: false,
      teleprompter_state: :stopped,
      countdown_value: 0,
      countdown_timer: nil,
      show_controls: true,
      show_voice_status: true,
      scroll_key: :os.system_time(:millisecond),
      scroll_position: 0,
      pause_time: nil,
      start_time: nil,
      microphone_permission: :unknown,
      microphone_active: false,
      microphone_error: nil
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
  def handle_event("toggle_add_mode", %{"mode" => mode}, socket) do
    new_mode = String.to_existing_atom(mode)

    socket =
      if new_mode == :default do
        Enum.reduce(socket.assigns.uploads.file.entries, socket, fn entry, acc ->
          cancel_upload(acc, :file, entry.ref)
        end)
        |> assign(uploaded_script: "")
        |> assign(upload_error: nil)
      else
        socket
      end

    socket
    |> assign(script_mode: new_mode)
    |> noreply()
  end

  @impl true
  def handle_event("update_script", %{"editor" => %{"content" => content}}, socket) do
    word_count = count_words(content)

    socket
    |> assign(script: content)
    |> assign(word_count: word_count)
    |> noreply()
  end

  @impl true
  def handle_event("validate", _params, socket) do
    upload_error =
      if String.length(String.trim(socket.assigns.script)) > 0 &&
           socket.assigns.uploads.file.entries != [] do
        "Please clear the text editor before uploading a file."
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
      socket
      |> start_teleprompter()
      |> noreply()
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
  def handle_event("update_mode", %{"mode" => mode}, socket) do
    mode = String.to_atom(mode)
    updated_settings = %{socket.assigns.settings | mode: mode}

    socket
    |> assign(settings: updated_settings)
    |> noreply()
  end

  @impl true
  def handle_event("update_font_family", %{"font-family" => font_family}, socket) do
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

  @impl true
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

  @impl true
  def handle_event("toggle_teleprompter", _params, socket) do
    case socket.assigns.teleprompter_state do
      :playing ->
        socket
        |> assign(teleprompter_state: :paused)
        |> noreply()

      :paused ->
        socket
        |> assign(teleprompter_state: :playing)
        |> noreply()

      _ ->
        noreply(socket)
    end
  end

  @impl true
  def handle_event("toggle_voice_control", _params, socket) do
    case socket.assigns.teleprompter_state do
      :voice_listening ->
        socket
        |> assign(teleprompter_state: :stopped)
        |> push_event("deactivate_microphone", %{})
        |> noreply()

      _ ->
        if socket.assigns.microphone_permission == :granted and socket.assigns.microphone_active do
          socket
          |> assign(teleprompter_state: :voice_listening)
          |> noreply()
        else
          socket
          |> push_event("request_microphone_permission", %{})
          |> noreply()
        end
    end
  end

  def handle_event("show_controls", _params, socket) do
    socket
    |> assign(show_controls: true)
    |> noreply()
  end

  def handle_event("hide_controls", _params, socket) do
    socket
    |> assign(show_controls: false)
    |> noreply()
  end

  def handle_event("show_voice_status", _params, socket) do
    socket
    |> assign(show_voice_status: true)
    |> noreply()
  end

  def handle_event("hide_voice_status", _params, socket) do
    socket
    |> assign(show_voice_status: false)
    |> noreply()
  end

  @impl true
  def handle_event("show_teleprompter_settings", _params, socket) do
    socket
    |> stop_teleprompter()
    |> noreply()
  end

  @impl true
  def handle_event("microphone_permission_granted", _params, socket) do
    socket
    |> assign(microphone_permission: :granted)
    |> push_event("activate_microphone", %{})
    |> noreply()
  end

  @impl true
  def handle_event("microphone_activated", _params, socket) do
    socket
    |> assign(microphone_active: true)
    |> assign(teleprompter_state: :voice_listening)
    |> noreply()
  end

  @impl true
  def handle_event("microphone_deactivated", _params, socket) do
    socket
    |> assign(microphone_active: false)
    |> assign(teleprompter_state: :stopped)
    |> noreply()
  end

  @impl true
  def handle_info(:countdown_tick, socket) do
    new_countdown = socket.assigns.countdown_value - 1

    if new_countdown > 0 do
      Process.send_after(self(), :countdown_tick, 1000)

      socket
      |> assign(countdown_value: new_countdown)
      |> noreply()
    else
      socket
      |> assign(
        teleprompter_state: :playing,
        countdown_value: 0,
        start_time: :os.system_time(:millisecond)
      )
      |> restart_scroll_animation()
      |> noreply()
    end
  end
end
