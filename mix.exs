defmodule Liquio.Mixfile do
	use Mix.Project

	def project() do
		[
			app: :liquio,
			version: "0.0.1",
			elixir: "~> 1.6.0",
			elixirc_paths: elixirc_paths(Mix.env),
			compilers: [:phoenix, :gettext] ++ Mix.compilers,
			build_embedded: Mix.env == :prod,
			start_permanent: Mix.env == :prod,
			deps: deps()
		]
	end

	def application() do
		[
			mod: {Liquio, []},
			extra_applications: [
				:phoenix, :phoenix_html, :cowboy, :logger, :gettext, :ssl, :edeliver
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
			{:edeliver, "~> 1.4.2"},
			{:cors_plug, "~> 1.1"},
			{:phoenix_html, "~> 2.4"},
			{:gettext, "~> 0.9"},
			{:cowboy, "~> 1.0"},
			{:httpotion, "~> 3.0.0"},
			{:timex, "~> 3.0"},
			{:cachex, "~> 2.0"},
			{:uuid, "~> 1.1"},

		]
	end
end
