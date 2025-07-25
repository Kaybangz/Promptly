defmodule PromptlyWeb.Live.Utils.FileProcessing do
  @moduledoc """
  Handles file processing utilities for extracting text from various file types
  (DOCX, PDF, TXT) and managing file-related operations. Provides error
  handling and type validation for file uploads in the LiveView context.
  """

  def process_content(content) when is_binary(content) do
    case String.trim(content) do
      "" -> "[File is empty or contains only whitespace]"
      trimmed -> trimmed
    end
  end

  def extract_text_from_file(%{type: :docx, path: path}) do
    try do
      charlist_path = String.to_charlist(path)

      case Docxelixir.read_paragraphs(charlist_path) do
        paragraphs when is_list(paragraphs) ->
          combined_text = Enum.join(paragraphs, "\n\n")
          {:ok, combined_text}

        {:error, reason} ->
          {:error, "Failed to read DOCX file: #{reason}"}
      end
    rescue
      e ->
        {:error, "Exception during DOCX extraction: #{Exception.message(e)}"}
    end
  end

  def extract_text_from_file(%{type: :pdf, path: path}) do
    try do
      pages = Enum.to_list(0..99)

      case PdfExtractor.PdfPlumber.extract_text(path, pages, %{}) do
        text_map when is_map(text_map) and map_size(text_map) > 0 ->
          combined_text =
            text_map
            |> Enum.sort_by(fn {page_num, _text} -> page_num end)
            |> Enum.map(fn {_page_num, text} -> text end)
            |> Enum.join("\n\n--- Page Break ---\n\n")

          {:ok, combined_text}

        text_map when is_map(text_map) and map_size(text_map) == 0 ->
          {:error, "No text found in PDF or PDF has no pages"}

        _ ->
          {:error, "Unexpected response from PDF extractor"}
      end
    rescue
      e ->
        {:error, "Exception during PDF extraction: #{Exception.message(e)}"}
    end
  end

  def extract_text_from_file(%{type: :txt, path: path}) do
    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, "Failed to read TXT file: #{reason}"}
    end
  end

  def get_file_extension(filename) do
    filename
    |> Path.extname()
    |> String.downcase()
    |> String.trim_leading(".")
  end

  def get_file_type(filename) do
    case get_file_extension(filename) do
      "pdf" -> :pdf
      "txt" -> :txt
      "docx" -> :docx
      _ -> :unknown
    end
  end

  def error_to_string(:too_large), do: "File is too large (max 10MB)"
  def error_to_string(:external_client_failure), do: "Something went terribly wrong"

  def error_to_string(:not_accepted),
    do: "File type not supported (only PDF, TXT, and DOCX files)"

  def error_to_string(:too_many_files), do: "Too many files (max 1 file)"
  def error_to_string(err), do: "Upload error: #{inspect(err)}"
end
