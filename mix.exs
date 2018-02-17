defmodule Liquio.Mixfile do
	use Mix.Project

	def project() do
		[
			app: :liquio,
			version: "0.0.1",
			elixir: "~> 1.5.0",
			elixirc_paths: elixirc_paths(Mix.env),
			compilers: [:phoenix, :gettext] ++ Mix.compilers,
			build_embedded: Mix.env == :prod,
			start_permanent: Mix.env == :prod,
			aliases: aliases(),
			deps: deps()
		]
	end

	def application() do
		[
			mod: {Liquio, []},
			extra_applications: [
				:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
				:phoenix_ecto, :postgrex, :ssl, :edeliver
			]
		]
	end

	defp elixirc_paths(:test), do: ["lib", "test/support"]
	defp elixirc_paths(_),     do: ["lib"]

	defp deps() do
		[
			{:distillery, "~> 1.5", runtime: false},
			{:phoenix_live_reload, "~> 1.0", only: :dev, runtime: false},
			{:credo, "~> 0.5", only: [:dev, :test], runtime: false},
			{:phoenix, "~> 1.3.0", override: true},
			{:phoenix_pubsub, "~> 1.0"},
			{:edeliver, "~> 1.4.2"},
			{:cors_plug, "~> 1.1"},
			{:postgrex, ">= 0.0.0"},
			{:phoenix_ecto, "~> 3.2.0"},
			{:phoenix_html, "~> 2.4"},
			{:gettext, "~> 0.9"},
			{:cowboy, "~> 1.0"},
			{:uuid, "~> 1.1"},
			{:httpotion, "~> 3.0.0"},
			{:poison, "~> 3.0", override: true},
			{:timex, "~> 3.0"},
			{:timex_ecto, "~> 3.0"},
			{:floki, "~> 0.10.0"},
			{:secure_random, "~> 0.5"},
			{:cachex, "~> 2.0"},
			{:ed25519, "~> 1.0"},
			{:elixir_ipfs_api, "~> 0.1.0"}
		]
	end

	defp aliases() do
		[
			"ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
			"ecto.reset": ["ecto.drop", "ecto.setup"],
			"test": ["ecto.create --quiet", "ecto.migrate", "test"]
		]
	end
end
