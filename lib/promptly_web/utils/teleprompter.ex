defmodule Promptly.Utils.Teleprompter do
  @moduledoc false

  def start_teleprompter(socket) do
    socket = Phoenix.Component.assign(socket, show_teleprompter: true, scroll_position: 0)

    case socket.assigns.settings.mode do
      :manual ->
        if socket.assigns.settings.countdown_timer > 0 do
          Process.send_after(self(), :countdown_tick, 1000)
          Phoenix.Component.assign(socket,
            teleprompter_state: :countdown,
            countdown_value: socket.assigns.settings.countdown_timer
          )
        else
          Phoenix.Component.assign(socket,
            teleprompter_state: :playing,
            start_time: :os.system_time(:millisecond)
          )
          |> restart_scroll_animation()
        end

      :voice_controlled ->
        Phoenix.Component.assign(socket,
          teleprompter_state: :stopped,
          microphone_permission: :unknown,
          microphone_active: false,
          microphone_error: nil
        )
    end
  end

  def stop_teleprompter(socket) do
    if socket.assigns.countdown_timer do
      Process.cancel_timer(socket.assigns.countdown_timer)
    end

    Phoenix.Component.assign(socket,
      show_teleprompter: false,
      teleprompter_state: :stopped,
      countdown_value: 0,
      countdown_timer: nil,
      scroll_position: 0,
      pause_time: nil,
      start_time: nil,
      microphone_active: false,
      microphone_error: nil
    )
  end

  def restart_animation(socket) do
    Phoenix.Component.assign(socket, :settings, %{
      socket.assigns.settings
      | preview_scroll_key: :os.system_time(:millisecond)
    })
  end

  def restart_scroll_animation(socket) do
    Phoenix.Component.assign(socket,
      scroll_key: :os.system_time(:millisecond),
      scroll_position: 0
    )
  end

  def cleanup_microphone(socket) do
    Phoenix.Component.assign(socket,
      microphone_active: false,
      microphone_error: nil,
      teleprompter_state: :stopped
    )
  end
end
