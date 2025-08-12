defmodule DpTrim.Device do
  use GenServer
  require Logger

  # Roughly 50 events per full rotation of the trim wheel.
  per_turn = 50
  # The Cessna 172 allows for a range of 5 full turns in either direction.
  max_turns = 5
  # Thus, our minimums and maximums:
  @min per_turn * -max_turns
  @max per_turn * max_turns

  # Take-off trim in MSFS is 3% down, but that's out of a max trim of 22%.
  # This also seems to match the "TAKE OFF" indicator on the yoke itself.
  @takeoff round(@min * (0.03 / 0.22))

  # The motorised wheel has values from 634 (nose up) to 1110 (nose down) inclusive:
  @wheel_min 634
  @wheel_max 1110

  # Scale factor for converting from internal value to wheel position:
  @wheel_scale (@wheel_max - @wheel_min) / (@max - @min)

  def start_link(opts) do
    {uplink, opts} = Keyword.pop!(opts, :uplink)
    {port, opts} = Keyword.pop_lazy(opts, :port, &discover_port/0)

    GenServer.start_link(__MODULE__, {uplink, port}, opts)
  end

  defp discover_port do
    Circuits.UART.enumerate()
    |> Enum.filter(fn
      {_, %{vendor_id: 14109, product_id: 57039}} -> true
      {_, %{}} -> false
    end)
    |> then(fn
      [{port, _}] -> port
      [] -> raise "DesktopPilot trim wheel not connected"
      multi -> raise "Too many possible trim wheels: #{inspect(multi)}"
    end)
  end

  @impl true
  def init({uplink, port}) do
    {:ok, uart} = Circuits.UART.start_link()

    Logger.info("Connecting to DesktopPilot trim wheel on #{port}.")
    Circuits.UART.open(uart, port, speed: 115_200, active: true)

    value = send_trim(@takeoff, uart, uplink)
    {:ok, {uart, uplink, value}}
  end

  @impl true
  def handle_info({:circuits_uart, _, event}, {uart, uplink, old_value}) do
    value =
      handle_event(event, old_value)
      |> constrain(@min, @max)
      |> send_trim(uart, uplink)

    {:noreply, {uart, uplink, value}}
  end

  defp handle_event("{\"Direction\":\"Down\"}\n", v), do: v + 1
  defp handle_event("{\"Direction\":\"Up\"}\n", v), do: v - 1
  defp handle_event("{\"Sensitivity\":\"Low\"}\n", _), do: @takeoff

  defp handle_event("{\"Sensitivity\":\"High\"}\n", v) do
    IO.puts("Current value: #{v}")
    v
  end

  defp send_trim(value, uart, uplink) do
    Logger.debug("Trim wheel position: #{value}")
    Circuits.UART.write(uart, "{\"Value\":#{wheel_value(value)}}\n")
    DpTrim.Uplink.trim(uplink, uplink_value(value))
    value
  end

  defp constrain(value, min, max) do
    value
    |> max(min)
    |> min(max)
  end

  defp wheel_value(n) do
    (@wheel_max - (@max - n) * @wheel_scale)
    |> round()
    |> constrain(@wheel_min, @wheel_max)
  end

  # This implicitly assumes that @min is just -@max.
  defp uplink_value(n), do: n / @max
end
