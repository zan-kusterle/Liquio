defmodule Liquio.PollController do
	use Liquio.Web, :controller
	
	with_params(%{
		:node => {Plugs.NodeParam, [name: "id"]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def show(conn, %{:node => node, :user => user}) do
		calculation_opts = get_calculation_opts_from_conn(conn)
		conn
		|> render("show.json", poll: Node.preload(node, calculation_opts, user))
	end)

	with_params(%{
		:node => {Plugs.NodeParam, [name: "id"]},
		:user => {Plugs.CurrentUser, [require: false]}
	},
	def contributions(conn, %{:node => poll}) do
		contributions = poll
		|> Poll.calculate_contributions(get_calculation_opts_from_conn(conn))
		|> Enum.map(fn(contribution) ->
			%{
				:datetime => Timex.format!(contribution.datetime, "{ISO:Basic}"),
				:choice => contribution.choice,
				:voting_power => contribution.voting_power,
				:identity_id => contribution.identity_id
			}
		end)
		conn
		|> render("results.json", results: contributions)
	end)
end
