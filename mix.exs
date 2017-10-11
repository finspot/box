defmodule Box.Mixfile do
  use Mix.Project

  def project do
    [
      app: :box,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Box.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:tesla, "~> 0.7"},
      {:joken, "~> 1.0"},
      {:poison, ">= 1.0.0"}
    ]
  end
end
