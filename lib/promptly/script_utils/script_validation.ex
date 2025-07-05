defmodule Promptly.ScriptUtils.ScriptValidation do
  @moduledoc """
  Functions for validating script content and word counts.
  """

  @doc """
  Validates that a script has content (not empty).
  """
  def valid_character_count?(script) when is_binary(script) do
    trimmed_script = String.trim(script)
    String.length(trimmed_script) > 0
  end

  @doc """
  Counts the number of words in a text string.
  Splits on whitespace and excludes empty strings.
  """
  def count_words(text) when is_binary(text) do
    text
    |> String.trim()
    |> String.split(~r/\s+/)
    |> Enum.reject(&(&1 == ""))
    |> length()
  end
end
