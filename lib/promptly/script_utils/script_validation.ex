defmodule Promptly.ScriptUtils.ScriptValidation do
  @moduledoc """
  Functions for validating script content and word counts.
  """

  @max_words 5000

  @doc """
  Validates that a script's word count is within acceptable limits.
  """
  def valid_script?(word_count) when is_integer(word_count) do
    word_count <= max_number_of_words()
  end

  @doc """
  Validates that a script has content (not empty).
  """
  def valid_character_count?(script) when is_binary(script) do
    String.length(script) > 0
  end

  @doc """
  Returns the maximum allowed number of words in a script.
  """
  def max_number_of_words, do: @max_words

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
