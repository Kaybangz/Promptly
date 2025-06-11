defmodule PromptlyWeb.Components.Settings do
  use Phoenix.Component

  import PromptlyWeb.CoreComponents

  @doc """
  Renders the complete settings configuration form with live preview.
  """
  attr :script, :string, required: true
  attr :uploaded_script, :string, required: true
  attr :settings, :map, required: true

  def element(assigns) do
    preview_script =
      if assigns.uploaded_script && assigns.uploaded_script != "" do
        assigns.uploaded_script
      else
        assigns.script
      end

    assigns = assign(assigns, preview_script: preview_script)

    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
      <div>
        <h2 class="text-xl font-semibold text-gray-900 mb-6 border-b pb-2">
          Settings
        </h2>
        <div class="space-y-6">
          <.mode_selection {assigns} />
          <.font_family_selection {assigns} />
          <.speed_selection {assigns} />
          <.font_size_selection {assigns} />
          <.theme_selection {assigns} />
          <.mirror_mode_selection {assigns} />
          <.reset_button />
        </div>
      </div>
      <div>
        <h3 class="text-lg font-semibold text-gray-900 mb-4 border-b pb-2">
          Live Preview
        </h3>
        <.live_preview settings={@settings} script={@preview_script} />
      </div>
    </div>
    <div class="mt-8 flex justify-between">
      <.button
        phx-click="previous_step"
        class="bg-white text-black border px-4 py-2 rounded-button hover:hover:bg-gray-50"
      >
        Back
      </.button>
      <.button phx-click="next_step" class="bg-primary text-white px-4 py-2 rounded-button">
        Start Teleprompter
      </.button>
    </div>
    """
  end

  defp mode_selection(assigns) do
    ~H"""
    <div class="setting-group">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Mode Selection</h4>
      <div class="flex space-x-4">
        <label class="flex items-center">
          <input
            type="radio"
            name="mode"
            value="manual"
            checked={@settings.mode == :manual}
            phx-click="update_mode"
            phx-value-mode="manual"
            class="mr-2"
          />
          <span class="text-sm">Manual</span>
        </label>
        <label class="flex items-center">
          <input
            type="radio"
            name="mode"
            value="voice_controlled"
            checked={@settings.mode == :voice_controlled}
            phx-click="update_mode"
            phx-value-mode="voice_controlled"
            class="mr-2"
          />
          <span class="text-sm">Voice Controlled</span>
        </label>
      </div>
    </div>
    """
  end

  defp speed_selection(assigns) do
    ~H"""
    <div class="setting-group">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Speed Control</h4>
      <div class={[
        "grid grid-cols-4 gap-2",
        @settings.mode == :voice_controlled && "opacity-50 pointer-events-none"
      ]}>
        <button
          :for={speed <- speed_options()}
          type="button"
          phx-click="update_speed"
          phx-value-speed={speed}
          disabled={@settings.mode == :voice_controlled}
          class={[
            "px-3 py-2 text-xs rounded-button border transition-colors",
            speed == @settings.speed && "bg-primary text-white border-primary",
            speed != @settings.speed &&
              "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
          ]}
        >
          {speed}x
        </button>
      </div>
    </div>
    """
  end

  defp font_size_selection(assigns) do
    ~H"""
    <div class="setting-group text-">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Font Size</h4>
      <div class="grid grid-cols-5 gap-2">
        <button
          :for={font_size <- font_sizes()}
          type="button"
          phx-click="update_font_size"
          phx-value-font-size={font_size.value}
          class={[
            "px-3 py-2 text-xs rounded border transition-colors",
            font_size.value == @settings.font_size && "bg-primary text-white border-primary",
            font_size.value != @settings.font_size &&
              "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
          ]}
        >
          {font_size.label}
        </button>
      </div>
    </div>
    """
  end

  defp font_family_selection(assigns) do
    ~H"""
    <div class="mb-6 relative" phx-click-away="close_font_family_dropdown">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Font Family</h4>
      <button
        phx-click="toggle_font_family_dropdown"
        class="bg-white border border-gray-300 text-gray-900 hover:bg-gray-50 focus:ring-2 focus:ring-primary focus:outline-none font-medium rounded-button text-sm px-4 py-2.5 text-center inline-flex items-center justify-between w-full"
        type="button"
      >
        <span style={"font-family: #{@settings.font_family.family};"}>
          {@settings.font_family.name}
        </span>
        <%= if @settings.font_family.dropdown_open do %>
          <svg
            class="w-4 h-4"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="m18 15-6-6-6 6" />
          </svg>
        <% else %>
          <svg
            class="w-4 h-4"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="m6 9 6 6 6-6" />
          </svg>
        <% end %>
      </button>
      <div class={[
        "absolute z-10 bg-white divide-y divide-gray-100 rounded-lg shadow-lg w-full mt-1 border border-gray-200",
        if(@settings.font_family.dropdown_open, do: "block", else: "hidden")
      ]}>
        <ul class="py-2 text-sm text-gray-700" role="menu">
          <li :for={{name, family} <- font_families()} role="none">
            <button
              phx-click="update_font_family"
              phx-value-family={family}
              phx-value-name={name}
              class={[
                "block w-full text-left px-4 py-2 hover:bg-gray-100 transition-colors duration-150",
                if(@settings.font_family.family == family,
                  do: "bg-blue-50 text-primary font-medium",
                  else: "text-gray-700"
                )
              ]}
              style={"font-family: #{family};"}
              role="menuitem"
            >
              {name}
            </button>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp theme_selection(assigns) do
    ~H"""
    <div class="setting-group">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Theme Selection</h4>
      <div class="flex space-x-4">
        <label class="flex items-center">
          <input
            type="radio"
            name="theme"
            value="light"
            checked={@settings.theme == :light}
            phx-click="update_theme"
            phx-value-theme="light"
            class="mr-2"
          />
          <span class="text-sm">Light</span>
        </label>
        <label class="flex items-center">
          <input
            type="radio"
            name="theme"
            value="dark"
            checked={@settings.theme == :dark}
            phx-click="update_theme"
            phx-value-theme="dark"
            class="mr-2"
          />
          <span class="text-sm">Dark</span>
        </label>
      </div>
    </div>
    """
  end

  defp mirror_mode_selection(assigns) do
    ~H"""
    <div class="setting-group">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Mirror Mode</h4>
      <label class="flex items-center">
        <input
          type="checkbox"
          checked={@settings.mirror_mode}
          phx-click="update_mirror_mode"
          class="mr-2"
        />
        <span class="text-sm">Enable mirror mode</span>
      </label>
    </div>
    """
  end

  defp live_preview(assigns) do
    ~H"""
    <div class={preview_container_class(@settings)}>
      <div class="w-full" style={scroll_animation(@settings, @script)}>
        <p class="p-3" style={[preview_text_style(@settings), mirror_style(@settings)]}>
          {@script}
        </p>
      </div>
      <div
        :if={@settings.mode == :voice_controlled}
        class="absolute bottom-2 left-2 bg-green-400 bg-opacity-40 text-white text-xs px-2 py-1 rounded-button"
      >
        🎤 Voice Controlled Mode - Speed Control Disabled
      </div>
    </div>

    <style>
      @keyframes scroll-vertical-<%= @settings.preview_scroll_key %> {
        0% { transform: translateY(24rem); }
        100% { transform: translateY(-100%); }
      }
    </style>
    """
  end

  defp reset_button(assigns) do
    ~H"""
    <div class="setting-group border-t pt-4">
      <.button
        phx-click="reset_settings"
        class="w-full bg-white text-black px-4 py-2 rounded-button hover:hover:bg-gray-50 border transition-colors"
      >
        Reset to Defaults
      </.button>
    </div>
    """
  end

  defp speed_options do
    [0.5, 0.8, 1.0, 1.5, 2.0, 2.5, 3.0]
  end

  defp font_sizes,
    do: [
      %{label: "Small", value: 24},
      %{label: "Medium", value: 36},
      %{label: "Large", value: 48},
      %{label: "Extra Large", value: 64},
      %{label: "Huge", value: 80}
    ]

  defp font_families do
    [
      {"Arial", "Arial, sans-serif"},
      {"Helvetica", "Helvetica, sans-serif"},
      {"Times New Roman", "Times New Roman, serif"},
      {"Georgia", "Georgia, serif"},
      {"Courier New", "Courier New, monospace"},
      {"Verdana", "Verdana, sans-serif"},
      {"Trebuchet MS", "Trebuchet MS, sans-serif"},
      {"Comic Sans MS", "Comic Sans MS, cursive"},
      {"Impact", "Impact, sans-serif"},
      {"Palatino", "Palatino, serif"}
    ]
  end

  defp preview_container_class(%{theme: :light}) do
    "relative overflow-hidden h-96 border rounded-button bg-white text-black"
  end

  defp preview_container_class(%{theme: :dark}) do
    "relative overflow-hidden h-96 border rounded-button bg-black text-white"
  end

  defp scroll_animation(%{mode: :manual, preview_scroll_key: key, speed: speed, font_size: font_size}, script) do
    chars_per_line = max(1, trunc(400 / (font_size * 0.6)))
    total_lines = max(1, trunc(String.length(script) / chars_per_line))
    content_height_px = total_lines * font_size * 1.5 # line-height is 1.5

    total_distance = 384 + content_height_px

    base_pixels_per_second = 100
    duration = total_distance / (base_pixels_per_second * speed)

    "animation: scroll-vertical-#{key} #{duration}s linear infinite;"
  end

  defp scroll_animation(_, _), do: ""

  defp preview_text_style(%{font_size: size, font_family: %{family: family}}) do
    """
    font-size: #{size}px;
    font-family: #{family};
    line-height: 1.5;
    """
  end

  defp mirror_style(%{mirror_mode: false}), do: ""

  defp mirror_style(%{mirror_mode: true}),
    do:
      "-webkit-transform: scaleX(-1); -moz-transform: scaleX(-1); -ms-transform: scaleX(-1); transform: scaleX(-1);"
end
