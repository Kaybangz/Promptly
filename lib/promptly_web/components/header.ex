defmodule PromptlyWeb.Components.Header do
  @moduledoc """
  Header component with responsive nav_items, logo, and call-to-action button.

  ## Examples

      <Header.element
        nav_items={[
          %{text: "Nav item 1", href: "#link"},
          %{text: "Nav item 2", href: "#link"}
        ]}
        action={%{text: "Call to action", route: "/action"}}
      />
  """

  use Phoenix.Component

  attr :nav_items, :list, default: nil
  attr :action, :map, default: nil

  def element(assigns) do
    ~H"""
    <header class="fixed top-0 left-0 w-full bg-white z-50 shadow-sm">
      <div class="mx-auto px-4 py-4 flex items-center justify-between">
        <.logo />
        <.desktop_nav :if={@nav_items} nav_items={@nav_items} action={@action} />
        <.mobile_menu_button :if={show_mobile_menu?(@nav_items)} />
      </div>
      <.mobile_nav
        :if={show_mobile_menu?(@nav_items)}
        nav_items={@nav_items}
        action={@action}
      />
    </header>
    """
  end

  defp logo(assigns) do
    ~H"""
    <.link href="/" class="text-2xl font-['Pacifico'] text-secondary">
      Promptly
    </.link>
    """
  end

  defp desktop_nav(assigns) do
    ~H"""
    <nav class={[
      "md:flex items-center space-x-8",
      show_mobile_menu?(@nav_items) && "hidden"
    ]}>
      <.nav_link
        :for={item <- @nav_items}
        class="nav-link text-gray-700 hover:text-primary transition-colors"
        link={item}
      />
      <.call_to_action :if={@action} button={@action} />
    </nav>
    """
  end

  defp mobile_nav(assigns) do
    ~H"""
    <div class="md:hidden hidden bg-white border-t border-gray-200 py-2" id="mobileMenu">
      <div class="mx-auto px-6 py-4 sm:px-6 lg:px-8">
        <nav class="flex flex-col space-y-3 py-3">
          <.nav_link
            :for={item <- @nav_items}
            class="text-sm md:text-md text-gray-700 hover:text-primary font-medium py-2"
            link={item}
          />
          <.nav_link
            :if={@action}
            class="text-primary hover:text-primary-dark font-medium py-2"
            link={@action}
          />
        </nav>
      </div>
    </div>
    """
  end

  defp mobile_menu_button(assigns) do
    ~H"""
    <button
      class="md:hidden w-8 h-8 flex items-center justify-center"
      id="mobileMenuButton"
      aria-label="Toggle mobile menu"
    >
      <div class="w-5 h-5 flex items-center justify-center">
        <i class="ri-menu-3-line text-black text-xl" id="menuIcon"></i>
        <i class="ri-close-large-line text-black text-xl hidden" id="closeIcon"></i>
      </div>
    </button>
    """
  end

  defp call_to_action(assigns) do
    ~H"""
    <.nav_link
      class="ml-4 px-3 py-2 bg-primary text-white font-medium rounded-button whitespace-nowrap transition-all hover:bg-opacity-90"
      link={@button}
    />
    """
  end

  defp nav_link(%{link: %{route: route}} = assigns) do
    assigns = assigns |> assign(route: route)

    ~H"""
    <.link class={@class} navigate={@route}>
      {@link.text}
    </.link>
    """
  end

  defp nav_link(%{link: %{href: href}} = assigns) do
    assigns = assigns |> assign(href: href)

    ~H"""
    <.link class={@class} href={@href}>
      {@link.text}
    </.link>
    """
  end

  defp show_mobile_menu?(nav_items) when is_list(nav_items), do: length(nav_items) > 1
  defp show_mobile_menu?(_), do: false
end
