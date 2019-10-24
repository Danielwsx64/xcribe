defmodule Xcribe.MixProject do
  use Mix.Project

  def project do
    [
      app: :xcribe,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: application_mod(Mix.env()),
      extra_applications: [:logger]
    ]
  end

  defp application_mod(:test), do: {Xcribe.Support.Application, []}
  defp application_mod(_), do: {Xcribe, []}

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dev environment
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},

      # Test environment
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:phoenix, "~> 1.4.0", only: [:test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false}
    ]
  end
end
