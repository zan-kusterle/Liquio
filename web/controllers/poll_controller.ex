defmodule Liquio.PollController do
	use Liquio.Web, :controller

	plug :scrub_params, "poll" when action in [:create]
	def create(conn, %{"poll" => params}) do
		changeset = Poll.changeset(%Poll{}, params)
		case Poll.create(changeset) do
			{:ok, poll} ->
				poll = Map.put(poll, :results, Result.empty())
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_path(conn, :show, poll))
				|> render("show.json", poll: poll)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Liquio.ChangesetView, "error.json", changeset: changeset)
		end
	end

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.NumberParam, [name: "vote_weight_halving_days", whole: true]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url"]},
	},
	def show(conn, %{:poll => poll}) do
		results = Result.calculate(poll, get_calculation_opts_from_conn(conn))
		conn
		|> render("show.json", poll: poll |> Map.put(:results, results))
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url"]},
	},
	def contributions(conn, %{:poll => poll}) do
		contributions = poll
		|> Result.calculate_contributions(get_calculation_opts_from_conn(conn))
		|> Enum.map(fn(contribution) ->
			%{
				:datetime => Timex.format!(contribution.datetime, "{ISO}"),
				:choice => contribution.choice,
				:voting_power => contribution.voting_power,
				:identity_id => contribution.identity_id
			}
		end)
		conn
		|> render("results.json", results: contributions)
	end)
end
