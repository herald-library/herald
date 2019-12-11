defmodule Herald.MixProject do
  use Mix.Project

  def project do
    [
      app: :herald,
      version: "0.1.0-beta.5",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: "Library to validate and exchange messages",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: [
        links: %{
          github: "https://github.com/radsquare/herald"
        },
        licenses: ["MIT"]
      ],
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test),
    do: ["lib","test/support"]
  defp elixirc_paths(_),
    do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:ecto, "~> 3.2"},
      {:jason, "~> 1.1"},

      # Development or test dependencies
      {:faker, "~> 0.13",  only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end

  def docs() do
    [
      extra_section: "GUIDES",
      main: "1-quick-start",
      extras: [
        "guides/1-quick-start.md",
        "guides/2-concepts.md"
      ]
    ]
  end
end
