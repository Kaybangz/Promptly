defmodule Promptly.ScriptUtils.FileProcessing do
  @moduledoc """
  Functions for processing uploaded files and content.
  """

  @doc """
  Processes file content, handling empty files gracefully.
  Returns a meaningful message for empty files.
  """
  def process_content(content) when is_binary(content) do
    case String.trim(content) do
      "" -> "[File is empty or contains only whitespace]"
      trimmed -> trimmed
    end
  end

  @doc """
  Converts upload error atoms to human-readable strings.
  """
  def upload_error_to_string(:too_large), do: "The file is too large"
  def upload_error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def upload_error_to_string(:external_client_failure), do: "Something went terribly wrong"
  def upload_error_to_string(error), do: "Unknown error: #{inspect(error)}"
end
