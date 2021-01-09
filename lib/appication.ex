defmodule Yagg.Application do
  use Application

  def start(_type, _args) do
    port = System.get_env("PORT", "8000") |> String.to_integer()
    secure_port = System.get_env("SECURE_PORT", "443") |> String.to_integer()
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        ip: {0, 0, 0, 0},
        plug: Yagg.Endpoint,
        protocol_options: [idle_timeout: :infinity],
        options: [
          port: port,
          dispatch: [{:_,[
            {"/ws/[...]", Yagg.Websocket, []},
            {:_, Plug.Cowboy.Handler, {Yagg.Endpoint, []}}
          ]}]
        ]
      ),
      Plug.Cowboy.child_spec(
        scheme: :https,
        ip: {0, 0, 0, 0},
        plug: Yagg.Endpoint,
        protocol_options: [idle_timeout: :infinity],
        options: [
          port: secure_port,
          otp_app: :secure_app,
          keyfile: "/etc/letsencrypt/live/yagg-game.com/fullchain.pem",
          certfile: "/etc/letsencrypt/live/yagg-game.com/cert.pem",
          dispatch: [{:_,[
            {"/ws/[...]", Yagg.Websocket, []},
            {:_, Plug.Cowboy.Handler, {Yagg.Endpoint, []}}
          ]}]
        ]
      ),
      {DynamicSupervisor, name: Yagg.TableSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: Yagg.AISupervisor, strategy: :one_for_one},
    ]

    _ets_table = Yagg.Table.Player.init_db()
    opts = [strategy: :one_for_one, name: Yagg.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
