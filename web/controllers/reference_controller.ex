defmodule Democracy.ReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Reference
	alias Democracy.Poll
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug :scrub_params, "reference" when action in [:create]

	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:index]
	plug Democracy.Plugs.TrustMetricIds, {:trust_metric_ids, "trust_metric_url"} when action in [:index]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:index]
	
	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_id"}
	plug Democracy.Plugs.QueryId, {:reference_poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:show]
	plug Democracy.Plugs.TrustMetricIds, {:trust_metric_ids, "trust_metric_url"} when action in [:show]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:show]
	plug Democracy.Plugs.FloatQuery, {:for_choice, "for_choice"} when action in [:show]

	def index(conn, %{:poll => poll, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, "threshold" => threshold, :trust_metric_ids => trust_metric_ids}) do
		references = Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids)
		conn
		|> render("index.json", references: references)
	end

	def show(conn, %{:poll => poll, :reference_poll => reference_poll, :for_choice => for_choice, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		reference = Reference.get(poll, reference_poll, for_choice)
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		results = Result.calculate(reference.approval_poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)
		reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
		conn
		|> render("show.json", reference: reference)
	end
end