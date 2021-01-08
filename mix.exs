defmodule YaggServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :yagg_server,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: :true,
      deps: deps(),
      elixirc_paths: compiler_paths(Mix.env()),
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :unknown],
      ],
    ]
  end

  def compiler_paths(:test), do: ["test/helpers"] ++ compiler_paths(:prod)
  def compiler_paths(_), do: ["lib"]

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
      {:cors_plug, "~> 2.0"},
      {:plug_cowboy, "~> 2.2"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
    ]
  end
end
