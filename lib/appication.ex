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
      {PubSub, []}
    ]

    opts = [strategy: :one_for_one, name: YaggServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
