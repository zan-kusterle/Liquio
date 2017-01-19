defmodule Liquio.ReferenceController do
	use Liquio.Web, :controller

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.NumberParam, [name: "vote_weight_halving_days", whole: true]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url"]},
	},
	def index(conn, %{:poll => poll}) do
		references = Reference.for_poll(poll, get_calculation_opts_from_conn(conn))
		conn
		|> render("index.json", references: references)
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:reference_poll => {Plugs.ItemParam, [schema: Poll, name: "id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.NumberParam, [name: "vote_weight_halving_days", whole: true]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url"]},
	},
	def show(conn, %{:poll => poll, :reference_poll => reference_poll}) do
		reference = poll
		|> Reference.get(reference_poll)
		|> Repo.preload([:for_choice_poll, :reference_poll, :poll])
		results = Poll.calculate(reference.for_choice_poll, get_calculation_opts_from_conn(conn))
		reference = Map.put(reference, :for_choice_poll, Map.put(reference.for_choice_poll, :results, results))
		conn
		|> render("show.json", reference: reference)
	end)
end