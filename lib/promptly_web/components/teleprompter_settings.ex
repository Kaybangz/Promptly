defmodule PromptlyWeb.Components.TeleprompterSettings do
  @moduledoc """
  Renders the complete settings configuration form with live preview.
  """
  use Phoenix.Component

  import PromptlyWeb.CoreComponents

  attr :script, :string, default: ""
  attr :uploaded_script, :string, default: ""
  attr :settings, :map, default: %{}

  def element(assigns) do
    preview_script =
      if assigns.uploaded_script && assigns.uploaded_script != "" do
        assigns.uploaded_script
      else
        assigns.script
      end

    assigns = assign(assigns, script: preview_script)

    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 border-b pb-4">
      <div>
        <h2 class="text-xl font-semibold text-gray-900 mb-6 border-b pb-2">
          Settings
        </h2>
        <div class="space-y-6">
          <.mode_selection {assigns} />
          <.font_family_selection {assigns} />
          <.speed_selection {assigns} />
          <.font_size_selection {assigns} />
          <.countdown_timer_selection {assigns} />
          <.theme_selection {assigns} />
          <.mirror_mode_selection {assigns} />
          <.reset_button />
        </div>
      </div>
      <div>
        <h3 class="text-lg font-semibold text-gray-900 mb-4 border-b pb-2">
          Live Preview
        </h3>
        <.live_preview {assigns} />
      </div>
    </div>
    <.navigation_buttons />
    """
  end

  defp navigation_buttons(assigns) do
    ~H"""
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
      <h4 class="text-sm font-bold text-gray-700 mb-2">Speed</h4>
      <div class={[
        "grid grid-cols-4 gap-2",
        @settings.mode == :voice_controlled && "opacity-50 pointer-events-none"
      ]}>
        <.button
          :for={speed <- speed_options()}
          type="button"
          phx-click="update_speed"
          phx-value-speed={speed}
          disabled={@settings.mode == :voice_controlled}
          class={[
            "px-1 py-2 text-xs rounded-button border transition-colors",
            speed == @settings.speed && "bg-primary text-white border-primary",
            speed != @settings.speed &&
              "bg-white text-gray-700 border-gray-300 hover:bg-gray-50"
          ]}
        >
          {speed}x
        </.button>
      </div>
    </div>
    """
  end

  defp font_size_selection(assigns) do
    ~H"""
    <div class="setting-group text-">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Font Size</h4>
      <div class="grid grid-cols-5 gap-2">
        <.button
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
        </.button>
      </div>
    </div>
    """
  end

  defp font_family_selection(assigns) do
    ~H"""
    <div class="mb-6 relative">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Font Family</h4>
      <details class="relative w-full">
        <summary class="bg-white border border-gray-300 text-gray-900 hover:bg-gray-50 focus:ring-2 focus:ring-primary focus:outline-none font-medium rounded-button text-sm px-4 py-2.5 text-center inline-flex items-center justify-between w-full cursor-pointer list-none">
          <span style={"font-family: #{@settings.font_family};"}>
            {@settings.font_family |> String.split(",") |> List.first()}
          </span>
          <.icon name="hero-chevron-down-solid" class="w-3 h-3" />
        </summary>
        <div class="absolute z-10 bg-white divide-y divide-gray-100 rounded-lg shadow-lg w-full mt-1 border border-gray-200">
          <ul class="py-2 text-sm text-gray-700" role="menu">
            <li :for={font_family <- font_families()} role="none">
              <.button
                phx-click="update_font_family"
                phx-value-font-family={font_family}
                class={[
                  "block w-full text-left px-4 py-2 hover:bg-gray-100 transition-colors duration-150",
                  if(@settings.font_family == font_family,
                    do: "bg-blue-50 text-primary font-medium",
                    else: "text-gray-700"
                  )
                ]}
                style={"font-family: #{font_family};"}
                role="menuitem"
              >
                {font_family |> String.split(",") |> List.first()}
              </.button>
            </li>
          </ul>
        </div>
      </details>
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

  defp countdown_timer_selection(assigns) do
    ~H"""
    <div class="setting-group">
      <h4 class="text-sm font-bold text-gray-700 mb-2">Countdown Timer</h4>
      <div class={[
        "flex items-center space-x-2",
        @settings.mode == :voice_controlled && "opacity-50 pointer-events-none"
      ]}>
        <.button
          type="button"
          phx-click="update_countdown_timer"
          phx-value-action="decrement"
          disabled={@settings.mode == :voice_controlled}
          class="flex items-center justify-center w-8 h-8 bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 rounded-button transition-colors"
        >
          <.icon name="hero-minus-solid" class="w-4 h-4" />
        </.button>
        <div class="flex items-center justify-center min-w-16 px-3 py-2 bg-gray-50 border border-gray-300 rounded-button">
          <span class="text-sm font-medium text-gray-900">
            {@settings.countdown_timer}
          </span>
          <span class="text-xs text-gray-500 ml-1">
            {if @settings.countdown_timer == 1, do: "sec", else: "secs"}
          </span>
        </div>
        <.button
          type="button"
          phx-click="update_countdown_timer"
          phx-value-action="increment"
          disabled={@settings.mode == :voice_controlled}
          class="flex items-center justify-center w-8 h-8 bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 rounded-button transition-colors"
        >
          <.icon name="hero-plus-solid" class="w-4 h-4" />
        </.button>
      </div>
    </div>
    """
  end

  defp live_preview(assigns) do
    animation_key = {
      assigns.settings.preview_scroll_key,
      assigns.settings.speed,
      assigns.settings.font_size,
      assigns.settings.font_family,
      assigns.settings.mirror_mode
    }

    ~H"""
    <div class={preview_container_class(@settings)}>
      {Phoenix.HTML.raw("<style>#{heading_font_size(@settings)}</style>")}
      <div class="w-full h-full" style={mirror_style(@settings)}>
        <div
          class="p-2 w-full trix-content"
          id={"scroll-content-#{elem(animation_key, 0)}"}
          phx-update="ignore"
          {if @settings.mode == :manual, do: %{"phx-hook" => "PreviewScrollAnimation", "data-speed" => @settings.speed, "data-animation-key" => :erlang.phash2(animation_key)}, else: %{}}
          style={preview_text_style(@settings)}
        >
          {Phoenix.HTML.raw(@script)}
        </div>
      </div>
      <div
        :if={@settings.mode == :voice_controlled}
        class="absolute top-2 right-2 bg-green-400 bg-opacity-80 text-white text-xs px-2 py-1 rounded-button"
      >
        🎤 Voice control mode enabled
      </div>
    </div>
    """
  end

  defp reset_button(assigns) do
    ~H"""
    <div class="setting-group pt-3">
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
    [0.5, 0.8, 1.0, 1.5, 2.0, 2.5]
  end

  defp font_sizes,
    do: [
      %{label: "Smallest", value: 24},
      %{label: "Small", value: 36},
      %{label: "Medium", value: 48},
      %{label: "Large", value: 64},
      %{label: "Largest", value: 80}
    ]

  defp font_families do
    [
      "Arial, sans-serif",
      "Helvetica, sans-serif",
      "Times New Roman, serif",
      "Georgia, serif",
      "Courier New, monospace",
      "Verdana, sans-serif",
      "Trebuchet MS, sans-serif",
      "Comic Sans MS, cursive",
      "Impact, sans-serif",
      "Palatino, serif"
    ]
  end

  defp preview_container_class(%{theme: :light}) do
    "relative overflow-hidden h-96 border rounded-button bg-white text-black"
  end

  defp preview_container_class(%{theme: :dark}) do
    "relative overflow-hidden h-96 border rounded-button bg-black text-white"
  end

  defp preview_text_style(%{font_size: size, font_family: font_family}) do
    """
    font-size: #{size}px;
    font-family: #{font_family};
    line-height: 1.5;
    """
  end

  defp heading_font_size(%{font_size: base_size}) do
    """
    .trix-content h1 { font-size: #{base_size * 2.0}px; }
    """
  end

  defp mirror_style(%{mirror_mode: false}), do: ""

  defp mirror_style(%{mirror_mode: true}),
    do:
      "-webkit-transform: scaleX(-1); -moz-transform: scaleX(-1); -ms-transform: scaleX(-1); transform: scaleX(-1);"
end
