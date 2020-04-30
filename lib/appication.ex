defmodule YaggServer.Application do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: YaggServer.Endpoint,
        port: 4000,
        protocol_options: [idle_timeout: :infinity]
      ),
      {DynamicSupervisor, name: YaggServer.GameSupervisor, strategy: :one_for_one},
      {YaggServer.EventManager, name: YaggServer.EventManager}
    ]

    opts = [strategy: :one_for_one, name: YaggServer.Supervisor]
    IO.inspect(Supervisor.start_link(children, opts))
  end
end
