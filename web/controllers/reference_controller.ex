defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	with_params([
		{Plugs.ItemParam, :poll, [schema: Poll, name: "poll_id"]},
		{Plugs.DatetimeParam, :datetime, [name: "datetime"]},
		{Plugs.IntegerParam, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{Plugs.TrustMetricIdsParam, :trust_metric_ids, [name: "trust_metric_ids"]},
	],
	def index(conn, %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, "threshold" => threshold, :trust_metric_ids => trust_metric_ids}) do
		references = Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids)
		conn
		|> render("index.json", references: references)
	end)

	with_params([
		{Plugs.ItemParam, :poll, [schema: Poll, name: "poll_id"]},
		{Plugs.ItemParam, :reference_poll, [schema: Poll, name: "id"]},
		{Plugs.NumberParam, :for_choice, [name: "for_choice"]},
		{Plugs.DatetimeParam, :datetime, [name: "datetime"]},
		{Plugs.IntegerParam, :vote_weight_halving_days, [name: "vote_weight_halving_days"]},
		{Plugs.TrustMetricIdsParam, :trust_metric_ids, [name: "trust_metric_ids"]},
	],
	def show(conn, %{:poll => poll, :reference_poll => reference_poll, :for_choice => for_choice, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		reference = Reference.get(poll, reference_poll, for_choice)
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		results = Result.calculate(reference.approval_poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)
		reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
		conn
		|> render("show.json", reference: reference)
	end)
end