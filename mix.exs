defmodule Xcribe.MixProject do
  use Mix.Project

  @version "1.0.0"
  @description "A lib to generate API documentation from test specs"
  @links %{"GitHub" => "https://github.com/Finbits/xcribe"}

  def project do
    [
      app: :xcribe,
      version: @version,
      name: "Xcribe",
      docs: docs(),
      description: @description,
      elixir: "~> 1.18",
      package: package(),
      source_url: @links["GitHub"],
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      deps: deps()
    ]
  end

  def cli do
    [
      preferred_envs: [
        precommit: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "xcribe.doc": :test,
        "xcribe.serve": :test
      ]
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

  defp application_mod(:test) do
    {Xcribe.Application,
     test: true,
     children: [
       {Xcribe.Endpoint, []},
       {Xcribe.StaticEndpoint, []}
     ]}
  end

  defp application_mod(_), do: {Xcribe.Application, []}

  defp aliases do
    [precommit: ["compile --warnings-as-errors", "format", "credo", "test"]]
  end

  defp deps do
    [
      # Floors are the first releases without known security advisories.
      {:plug, ">= 1.18.5 and < 2.0.0"},

      # Dev environment
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},

      # Test environment
      {:phoenix, ">= 1.8.9 and < 2.0.0", only: [:dev, :test]},
      {:bandit, "~> 1.12", only: [:dev, :test]},
      {:floki, "~> 0.38", only: [:test]},
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.1", only: [:dev, :test], runtime: false}
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
        "README.md": [title: "Get starting"],
        "documentation/serving_doc.md": [title: "Serving doc"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ],
      groups_for_modules: doc_groups_for_modules()
    ]
  end

  defp doc_groups_for_modules do
    [
      Documenting: [Xcribe.Document, Xcribe.Formatter],
      "Describing the API": [Xcribe.Specification],
      Configuring: [Xcribe.Config],
      "Mix tasks": [Mix.Tasks.Xcribe.Doc, Mix.Tasks.Xcribe.Gen.Spec, Mix.Tasks.Xcribe.Serve],
      Serving: [Xcribe.Web.Plug]
    ]
  end
end
