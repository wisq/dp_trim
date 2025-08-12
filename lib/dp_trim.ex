defmodule DpTrim do
  use Application

  def start(_type, _args) do
    children = [
      {DpTrim.Uplink, name: DpTrim.Supervisor.Uplink},
      {DpTrim.Device, uplink: DpTrim.Supervisor.Uplink}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
