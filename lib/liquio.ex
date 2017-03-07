defmodule Liquio do
	use Application

	# See http://elixir-lang.org/docs/stable/elixir/Application.html
	# for more information on OTP Applications
	def start(_type, _args) do
		import Supervisor.Spec, warn: false

		children = [
			# Start the endpoint when the application starts
			supervisor(Liquio.Web.Endpoint, []),
			# Start the Ecto repository
			supervisor(Liquio.Repo, []),
			# Here you could define other workers and supervisors as children
			# worker(Liquio.Worker, [arg1, arg2, arg3]),
			worker(Cachex, [:results_cache, []]),
		]

		# See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
		# for other strategies and supported options
		opts = [strategy: :one_for_one, name: Liquio.Supervisor]
		Supervisor.start_link(children, opts)
	end
end
