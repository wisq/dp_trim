defmodule DpTrim.Uplink do
  use GenServer
  require Logger

  defp default_ip do
    value = System.get_env("CLS2SIM_IP", "127.0.0.1")

    value
    |> String.to_charlist()
    |> :inet.parse_address()
    |> then(fn
      {:ok, ip} -> ip
      {:error, :einval} -> raise "Bad CLS2SIM_IP env var: #{value}"
    end)
  end

  def start_link(opts) do
    {ip, opts} = Keyword.pop_lazy(opts, :ip, &default_ip/0)
    {port, opts} = Keyword.pop(opts, :port, 15090)

    GenServer.start_link(__MODULE__, {ip, port}, opts)
  end

  def trim(pid, value) when is_float(value) do
    GenServer.cast(pid, {:trim, value})
  end

  @impl true
  def init({ip, port} = target) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, true}])

    Logger.info("Sending trim values to #{:inet.ntoa(ip)}:#{port}.")

    :gen_udp.send(socket, target, <<
      # set override
      0xD1::unsigned-integer-32-little,
      # elevator axis
      0x1::unsigned-integer-32-little,
      # trim position
      0x2::unsigned-integer-32-little
    >>)

    {:ok, {socket, target}}
  end

  @impl true
  def handle_cast({:trim, value}, {socket, target} = state) do
    Logger.debug("Sending trim: #{value}")

    :gen_udp.send(socket, target, <<
      # set value
      0xCE::unsigned-integer-32-little,
      # elevator axis
      0x1::unsigned-integer-32-little,
      # trim position
      0x90::unsigned-integer-32-little,
      # value
      value::float-32-little
    >>)

    {:noreply, state}
  end

  @impl true
  def handle_info({:udp, socket, ip, port, <<1, 0, 0>>}, {socket, {ip, port}} = state) do
    # Command succesful, ignore.
    Logger.debug("Success from #{:inet.ntoa(ip)}:#{port}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:udp, _socket, ip, port, data}, state) do
    Logger.warning("Unknown response from #{:inet.ntoa(ip)}:#{port} -- #{inspect(data)}")
    {:noreply, state}
  end
end
