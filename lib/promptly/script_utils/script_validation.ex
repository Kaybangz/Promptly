defmodule Promptly.ScriptUtils.ScriptValidation do
  @moduledoc """
  Functions for validating script content and word counts.
  """

  @doc """
  Counts the number of words in the text editor.
  Properly handles lists, paragraphs, and other structured content.
  Splits on whitespace and excludes empty strings.
  """
  def count_words(content) when is_binary(content) do
    content
    |> strip_html_tags()
    |> normalize_whitespace()
    |> String.trim()
    |> case do
      "" -> 0
      text ->
        text
        |> String.split(~r/\s+/)
        |> Enum.reject(&(&1 == ""))
        |> length()
    end
  end

  @doc """
  Remove HTML tags and decode HTML entities.
  Converts block elements to ensure proper word separation.
  """
  defp strip_html_tags(html) do
    html
    |> String.replace(~r/<\/(p|div|li|ul|ol|h[1-6]|blockquote|pre)>/i, "\n")
    |> String.replace(~r/<(p|div|li|ul|ol|h[1-6]|blockquote|pre)[^>]*>/i, "\n")
    |> String.replace(~r/<br\s*\/?>/i, " ")
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace(~r/&[a-zA-Z0-9#]+;/, "")
  end

  @doc """
  Normalizes whitespace by converting multiple whitespace characters
  (including newlines, tabs) to single spaces.
  """
  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
  end
end
