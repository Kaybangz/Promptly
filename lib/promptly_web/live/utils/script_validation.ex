defmodule PromptlyWeb.Live.Utils.ScriptValidation do
  @moduledoc false

  def count_words(content) when is_binary(content) do
    content
    |> strip_html_tags()
    |> normalize_whitespace()
    |> String.trim()
    |> case do
      "" ->
        0

      text ->
        text
        |> String.split(~r/\s+/)
        |> Enum.reject(&(&1 == ""))
        |> length()
    end
  end

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

  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
  end
end
