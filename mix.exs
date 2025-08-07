defmodule CList.MixProject do
  use Mix.Project

  def project do
    [
      app: :clist,
      description: "A module to work with circular lists. A circular lists is a finite list that can be traversed as if it were infinite.",
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package() do
    [
      name: "clist",
      description: "A module to work with circular lists. A circular lists is a finite list that can be traversed as if it were infinite.",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mailcmd/clist"},
      source_url: "https://github.com/mailcmd/clist",
    ]
  end
end
