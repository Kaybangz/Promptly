defmodule PromptlyWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use PromptlyWeb, :html

  alias PromptlyWeb.Components.Header

  import PromptlyWeb.CoreComponents

  embed_templates "page_html/*"
end
