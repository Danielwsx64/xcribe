defmodule Xcribe.MixProject do
  use Mix.Project

  @version "0.2.0"
  @description "A lib to generate API documentation from test specs"
  @links %{"GitHub" => "https://github.com/danielwsx64/xcribe"}

  def project do
    [
      app: :xcribe,
      version: @version,
      name: "XCribe",
      docs: docs(),
      description: @description,
      elixir: "~> 1.8",
      package: package(),
      source_url: @links["GitHub"],
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

  def application do
    [
      mod: application_mod(Mix.env()),
      extra_applications: [:logger]
    ]
  end

  defp application_mod(:test), do: {Xcribe.Support.Application, []}
  defp application_mod(_), do: {Xcribe, []}

  defp deps do
    [
      # Dev environment
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},

      # Test environment
      {:jason, "~> 1.1", only: [:dev, :test]},
      {:phoenix, "~> 1.4.10", only: [:test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: @links
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md": [title: "README"]
      ],
      groups_for_modules: doc_groups_for_modules()
    ]
  end

  defp doc_groups_for_modules do
    [
      BluePrint: [
        Xcribe.ApiBlueprint,
        Xcribe.ApiBlueprint.Formatter,
        Xcribe.ApiBlueprint.Templates
      ],
      Swagger: [
        Xcribe.Swagger,
        Xcribe.Swagger.Descriptor,
        Xcribe.Swagger.Formatter
      ],
      Helpers: [
        Xcribe.Helpers.Document,
        Xcribe.Helpers.Formatter
      ]
    ]
  end
end
