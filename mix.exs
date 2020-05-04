defmodule YaggServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :yagg_server,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Yagg.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.10"},
      {:cowboy, "~> 2.7"},
      {:poison, "~> 4.0"},
      {:gen_stage, "~> 1.0"},
      {:plug_cowboy, "~> 2.2"}
    ]
  end
end
