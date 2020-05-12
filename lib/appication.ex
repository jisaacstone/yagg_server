defmodule Yagg.Application do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        ip: {0, 0, 0, 0},
        plug: Yagg.Endpoint,
        port: 8000,
        protocol_options: [idle_timeout: :infinity]
      ),
      {DynamicSupervisor, name: Yagg.GameSupervisor, strategy: :one_for_one},
    ]

    opts = [strategy: :one_for_one, name: Yagg.Supervisor]
    IO.inspect(Supervisor.start_link(children, opts))
  end
end
