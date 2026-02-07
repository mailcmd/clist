defmodule CList.MixProject do
  use Mix.Project

  def project do
    [
      app: :clist,
      name: "Circular List",
      description: "A module to work with circular lists. A circular lists is a finite list that can be traversed as if it were infinite.",
      version: "0.1.3",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      name: :clist,
      description: "A module to work with circular lists. A circular lists is a finite list that can be traversed as if it were infinite.",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mailcmd/clist"},
      source_url: "https://github.com/mailcmd/clist",
    ]
  end
end
