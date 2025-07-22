defmodule PromptlyWeb.Components.TeleprompterDisplay do
  @moduledoc """
  Full-screen teleprompter display component with controls.
  """
  use Phoenix.Component

  import PromptlyWeb.CoreComponents

  attr :script, :string, required: true
  attr :uploaded_script, :string, default: ""
  attr :settings, :map, required: true
  attr :show_teleprompter, :boolean, default: false
  attr :teleprompter_state, :atom, default: :stopped
  attr :countdown_value, :integer, default: 0
  attr :scroll_key, :integer, default: 0
  attr :scroll_position, :integer, default: 0
  attr :show_controls, :boolean, default: true
  attr :show_voice_status, :boolean, default: true
  attr :microphone_active, :boolean, default: false

  def element(assigns) do
    script =
      if assigns.uploaded_script && assigns.uploaded_script != "" do
        assigns.uploaded_script
      else
        assigns.script
      end

    assigns = assign(assigns, script: script)

    ~H"""
    <div
      :if={@show_teleprompter}
      class="fixed inset-0 z-50 flex items-center justify-center"
      style="background-color: rgba(0, 0, 0, 0.9);"
      phx-hook="TeleprompterControls"
      id="teleprompter-display"
    >
      <div phx-hook="VoiceTeleprompterScrollAnimation" id="teleprompter-microphone" class="hidden">
      </div>
      <div class={teleprompter_container_class(@settings)}>
        <.countdown_overlay
          teleprompter_state={@teleprompter_state}
          countdown_value={@countdown_value}
          settings={@settings}
        />
        <.teleprompter_content
          teleprompter_state={@teleprompter_state}
          settings={@settings}
          script={@script}
          scroll_key={@scroll_key}
          scroll_position={@scroll_position}
        />
        <.controls_section
          show_controls={@show_controls}
          teleprompter_state={@teleprompter_state}
          settings={@settings}
        />
        <.voice_status_indicator
          show_voice_status={@show_voice_status}
          teleprompter_state={@teleprompter_state}
          microphone_active={@microphone_active}
          settings={@settings}
        />
      </div>
    </div>
    <.teleprompter_styles scroll_key={@scroll_key} scroll_position={@scroll_position} />
    """
  end

  defp countdown_overlay(assigns) do
    ~H"""
    <div
      :if={@teleprompter_state == :countdown and @settings.mode == :manual}
      class="absolute inset-0 flex items-center justify-center z-20"
      style="background-color: inherit;"
    >
      <div class={countdown_display_class(@settings)}>
        <div class="text-8xl font-bold mb-4 animate-pulse">
          {@countdown_value}
        </div>
        <div class="text-2xl">
          Get Ready...
        </div>
      </div>
    </div>
    """
  end

  defp teleprompter_content(assigns) do
    ~H"""
    <div
      :if={@teleprompter_state != :countdown}
      class="relative h-full w-full overflow-hidden"
      style={mirror_transform(@settings)}
      id="teleprompter-container"
      phx-hook="ManualTeleprompterScrollAnimation"
    >
      {Phoenix.HTML.raw("<style>#{heading_font_size(@settings)}</style>")}
      <div
        class="absolute inset-0 p-8 trix-content"
        id="teleprompter-content"
        style={[
          teleprompter_text_style(@settings),
          scroll_animation(@settings, @teleprompter_state, @scroll_key, @scroll_position)
        ]}
      >
        {Phoenix.HTML.raw(@script)}
      </div>
    </div>
    """
  end

  defp controls_section(assigns) do
    ~H"""
    <div class={[
      controls_container_class(@settings),
      controls_visibility_class(@show_controls)
    ]}>
      <.settings_button settings={@settings} />
      <.play_pause_button teleprompter_state={@teleprompter_state} settings={@settings} />
      <.microphone_button teleprompter_state={@teleprompter_state} settings={@settings} />
      <.home_button settings={@settings} />
    </div>
    """
  end

  defp home_button(assigns) do
    ~H"""
    <.link href="/" class={control_button_class(@settings)} title="Home">
      <.icon name="hero-home" class="w-5 h-5" />
    </.link>
    """
  end

  defp play_pause_button(assigns) do
    ~H"""
    <.button
      :if={@settings.mode == :manual}
      phx-click="toggle_teleprompter"
      class={control_button_class(@settings)}
      title={if @teleprompter_state == :playing, do: "Pause", else: "Play"}
    >
      <%= if @teleprompter_state == :playing do %>
        <.icon name="hero-pause" class="w-5 h-5" />
      <% else %>
        <.icon name="hero-play" class="w-5 h-5" />
      <% end %>
    </.button>
    """
  end

  defp microphone_button(assigns) do
    ~H"""
    <.button
      :if={@settings.mode == :voice_controlled}
      phx-click="toggle_voice_control"
      class={[
        control_button_class(@settings),
        if(@teleprompter_state == :voice_listening,
          do: "bg-green-500 hover:bg-green-600 text-white animate-pulse",
          else: ""
        )
      ]}
      title={
        if @teleprompter_state == :voice_listening,
          do: "Disable Microphone",
          else: "Enable Microphone"
      }
    >
      <.icon name="hero-microphone" class="w-5 h-5" />
    </.button>
    """
  end

  defp settings_button(assigns) do
    ~H"""
    <.button
      phx-click="show_teleprompter_settings"
      class={control_button_class(@settings)}
      title="Settings"
    >
      <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
    </.button>
    """
  end

  defp voice_status_indicator(assigns) do
    ~H"""
    <div
      :if={@settings.mode == :voice_controlled}
      class={[
        "absolute top-8 left-1/2 transform -translate-x-1/2 text-white px-4 py-2 rounded-full flex items-center space-x-1",
        if(@teleprompter_state == :voice_listening,
          do: "bg-green-500 hover:bg-green-600",
          else: "bg-red-500 bg-opacity-90"
        ),
        if(@show_voice_status, do: "opacity-100", else: "opacity-0"),
        "transition-opacity duration-300 ease-in-out"
      ]}
      data-voice-listening={@teleprompter_state == :voice_listening}
    >
      <%= if @teleprompter_state == :voice_listening and @microphone_active do %>
        <div class="w-2 h-2 bg-white rounded-full animate-pulse"></div>
        <span class="text-sm font-medium">Listening...</span>
      <% else %>
        <.icon name="hero-microphone" class="w-4 h-4 animate-pulse" />
        <span class="text-sm font-medium">Microphone Access Required</span>
      <% end %>
    </div>
    """
  end

  defp teleprompter_styles(assigns) do
    ~H"""
    <style>
      @keyframes scroll-teleprompter-<%= @scroll_key %> {
        0% { transform: translateY(var(--viewport-height, 100vh)); }
        100% { transform: translateY(calc(-1 * var(--content-height, 100%))); }
      }
      @keyframes scroll-teleprompter-resume-<%= @scroll_key %> {
        0% { transform: translateY(<%= @scroll_position %>px); }
        100% { transform: translateY(calc(-1 * var(--content-height, 100%))); }
      }
      #teleprompter-content {
        pointer-events: none;
      }
      .teleprompter-paused {
        animation-play-state: paused !important;
      }
      .controls-hidden {
        opacity: 0;
        pointer-events: none;
        transition: opacity 0.3s ease-in-out;
      }
      .controls-visible {
        opacity: 1;
        pointer-events: auto;
        transition: opacity 0.3s ease-in-out;
      }
    </style>
    """
  end

  defp teleprompter_container_class(%{theme: :light}) do
    "w-full h-full bg-white text-black relative"
  end

  defp teleprompter_container_class(%{theme: :dark}) do
    "w-full h-full bg-black text-white relative"
  end

  defp countdown_display_class(%{theme: :light}) do
    "text-center text-black"
  end

  defp countdown_display_class(%{theme: :dark}) do
    "text-center text-white"
  end

  defp controls_container_class(%{theme: :light}) do
    "absolute bottom-8 left-1/2 transform -translate-x-1/2 flex space-x-4 bg-white bg-opacity-90 p-4 rounded-full shadow-lg"
  end

  defp controls_container_class(%{theme: :dark}) do
    "absolute bottom-8 left-1/2 transform -translate-x-1/2 flex space-x-4 bg-black bg-opacity-90 p-4 rounded-full shadow-lg"
  end

  defp controls_visibility_class(true), do: "controls-visible"
  defp controls_visibility_class(false), do: "controls-hidden"

  defp control_button_class(%{theme: :light}) do
    "flex items-center justify-center w-12 h-12 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-full transition-colors duration-200"
  end

  defp control_button_class(%{theme: :dark}) do
    "flex items-center justify-center w-12 h-12 bg-gray-700 hover:bg-gray-600 text-white rounded-full transition-colors duration-200"
  end

  defp teleprompter_text_style(%{font_size: size, font_family: font_family}) do
    """
    font-size: #{size}px;
    font-family: #{font_family};
    line-height: 1.6;
    text-align: left;
    padding: 0 2rem;
    """
  end

  defp scroll_animation(
         %{mode: :manual, speed: speed},
         state,
         scroll_key,
         scroll_position
       )
       when state in [:playing, :paused] do
    animation_name =
      if scroll_position == 0 do
        "scroll-teleprompter-#{scroll_key}"
      else
        "scroll-teleprompter-resume-#{scroll_key}"
      end

    play_state = if state == :paused, do: "paused", else: "running"

    """
    --adjusted-scroll-duration: calc(var(--base-scroll-duration, 20s) / #{speed});
    animation: #{animation_name} var(--adjusted-scroll-duration, 20s) linear infinite;
    animation-fill-mode: forwards;
    animation-play-state: #{play_state};
    pointer-events: none;
    """
  end

  defp scroll_animation(_, _, _, _) do
    """
    pointer-events: none;
    """
  end

  defp heading_font_size(%{font_size: base_size}) do
    """
    .trix-content h1 { font-size: #{base_size * 2.0}px; }
    """
  end

  defp mirror_transform(%{mirror_mode: false}), do: ""

  defp mirror_transform(%{mirror_mode: true}) do
    "transform: scaleX(-1);"
  end
end
