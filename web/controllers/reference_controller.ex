defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.IntegerParam, [name: "vote_weight_halving_days"]},
		:trust_metric_ids => {Plugs.TrustMetricIdsParam, [name: "trust_metric_ids"]},
	},
	def index(conn, %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, "threshold" => threshold, :trust_metric_ids => trust_metric_ids}) do
		references = Reference.for_poll(poll, calculate_opts_from_conn(conn))
		conn
		|> render("index.json", references: references)
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:reference_poll => {Plugs.ItemParam, [schema: Poll, name: "id"]},
		:for_choice => {Plugs.NumberParam, [name: "for_choice"]},
		:datetime => {Plugs.DatetimeParam, [name: "datetime"]},
		:vote_weight_halving_days => {Plugs.IntegerParam, [name: "vote_weight_halving_days"]},
		:trust_metric_ids => {Plugs.TrustMetricIdsParam, [name: "trust_metric_ids"]},
	},
	def show(conn, %{:poll => poll, :reference_poll => reference_poll, :for_choice => for_choice, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		reference = Reference.get(poll, reference_poll, for_choice)
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		results = Results.calculate(reference.approval_poll, calculate_opts_from_conn(conn))
		reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
		conn
		|> render("show.json", reference: reference)
	end)
end