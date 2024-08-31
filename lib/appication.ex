defmodule Yagg.Application do
  @moduledoc "the http server"
  use Application

  def server_spec() do
    if System.get_env("MIX_ENV") == "prod" do
      Plug.Cowboy.child_spec(
        scheme: :https,
        ip: {0, 0, 0, 0},
        plug: Yagg.Endpoint,
        protocol_options: [idle_timeout: :infinity],
        options: [
          port: 443,
          cipher_suite: :strong,
          otp_app: :secure_app,
          keyfile: "/etc/letsencrypt/live/yagg-game.com/privkey.pem",
          certfile: "/etc/letsencrypt/live/yagg-game.com/fullchain.pem",
          dispatch: [{:_,[
            {"/ws/[...]", Yagg.Websocket, []},
            {:_, Plug.Cowboy.Handler, {Yagg.Endpoint, []}}
          ]}]
        ]
      )
    else 
      port = System.get_env("PORT", "8000") |> String.to_integer()
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
      )
    end
  end

  def start(_type, _args) do
    children = [
      server_spec(),
      {Registry, keys: :unique, name: Registry.TableNames},
      {DynamicSupervisor, name: Yagg.TableSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: Yagg.AISupervisor, strategy: :one_for_one},
    ]

    _ets_table = Yagg.Table.Player.init_db()
    opts = [strategy: :one_for_one, name: Yagg.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
