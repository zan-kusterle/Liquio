defmodule Liquio.Mixfile do
  use Mix.Project

  def project do
    [app: :liquio,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Liquio, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :postgrex, :ssl, :uuid, :httpotion, :timex, :timex_ecto, :guardian, :cors_plug, :comeonin, :basic_auth, :edeliver]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.0"},
     {:exrm, "~> 1.0.8"},
     {:edeliver, "~> 1.3.0"},
     {:phoenix_pubsub, "~> 1.0"},
     {:cors_plug, "~> 1.1"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_ecto, "~> 3.0-rc"},
     {:phoenix_html, "~> 2.4"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:guardian, "~> 0.10.0"},
     {:uuid, "~> 1.1"},
     {:httpotion, "~> 3.0.0"},
     {:timex, "~> 2.2.1"},
     {:timex_ecto, "~> 1.1.3"},
     {:comeonin, "~> 2.5"},
     {:basic_auth, "~> 1.0.0"},
     {:credo, "~> 0.3", only: [:dev, :test]}
   ]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
