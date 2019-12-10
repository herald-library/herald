defmodule Herald.MixProject do
  use Mix.Project

  def project do
    [
      app: :herald,
      version: "0.1.0-beta.3",
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
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Herald.Application, []}
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
      {:amqp, "~> 1.3"},
      {:gen_stage, "~> 0.11"},

      # Development or test dependencies
      {:faker, "~> 0.13",  only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end
end
