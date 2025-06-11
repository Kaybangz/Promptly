defmodule PromptlyWeb.TeleprompterLive do
  use PromptlyWeb, :live_view

  alias PromptlyWeb.Header
  alias PromptlyWeb.Script

  import Promptly.ScriptUtils.FileProcessing
  import Promptly.ScriptUtils.ScriptValidation

  @total_steps 3

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
      settings: %{},
      changeset: nil
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

  def handle_event("clear_file", _params, socket) do
    socket
    |> assign(uploaded_script: "")
    |> noreply()
  end
end
