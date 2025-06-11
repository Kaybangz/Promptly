defmodule PromptlyWeb.Header do
  use Phoenix.Component

  @doc """
  Renders a header component.
  """
  attr :logo, :map, required: true
  attr :navigation, :list, required: true
  attr :cta, :map, default: nil

  def component(assigns) do
    ~H"""
    <header class="fixed top-0 left-0 w-full bg-white z-50 shadow-sm">
      <div class="container mx-auto px-6 py-4 flex items-center justify-between">
        <.brand_logo logo={@logo} />
        <.desktop_navigation navigation={@navigation} cta={@cta} />
        <.mobile_menu_toggle />
      </div>
      <.mobile_navigation navigation={@navigation} cta={@cta} />
    </header>
    """
  end

  defp brand_logo(assigns) do
    ~H"""
    <.navigation_link class="text-2xl font-['Pacifico'] text-secondary" link={@logo} />
    """
  end

  defp desktop_navigation(assigns) do
    ~H"""
    <nav class="hidden md:flex items-center space-x-8">
      <.navigation_link
        :for={link <- @navigation}
        class="nav-link text-gray-700 hover:text-primary transition-colors"
        link={link}
      />
      <.call_to_action :if={@cta} button={@cta} />
    </nav>
    """
  end

  defp mobile_navigation(assigns) do
    ~H"""
    <div class="md:hidden hidden bg-white border-t border-gray-200 py-2" id="mobileMenu">
      <div class="container mx-auto px-6 py-4 sm:px-6 lg:px-8">
        <nav class="flex flex-col space-y-3 py-3">
          <.navigation_link
            :for={link <- @navigation}
            class="text-gray-700 hover:text-primary font-medium py-2"
            link={link}
          />
          <.navigation_link
            :if={@cta}
            class="text-primary hover:text-primary-dark font-medium py-2"
            link={@cta}
          />
        </nav>
      </div>
    </div>
    """
  end

  defp mobile_menu_toggle(assigns) do
    ~H"""
    <button
      class="md:hidden w-10 h-10 flex items-center justify-center"
      id="mobileMenuButton"
      aria-label="Toggle mobile menu"
    >
      <div class="w-6 h-6 flex items-center justify-center">
        <i class="ri-menu-3-line text-black text-2xl" id="menuIcon"></i>
        <i class="ri-close-large-line text-black text-2xl hidden" id="closeIcon"></i>
      </div>
    </button>
    """
  end

  defp call_to_action(assigns) do
    ~H"""
    <.navigation_link
      class="ml-4 px-3 py-2 bg-primary text-white font-medium rounded-button whitespace-nowrap transition-all hover:bg-opacity-90"
      link={@button}
    />
    """
  end

  defp navigation_link(%{link: %{route: route}} = assigns) do
    assigns = assigns |> assign(route: route)

    ~H"""
    <.link class={@class} navigate={@route}>
      {@link.text}
    </.link>
    """
  end

  defp navigation_link(%{link: %{href: href}} = assigns) do
    assigns = assigns |> assign(href: href)

    ~H"""
    <.link class={@class} href={@href}>
      {@link.text}
    </.link>
    """
  end
end
