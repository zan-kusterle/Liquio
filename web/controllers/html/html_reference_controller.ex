defmodule Democracy.HtmlReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result
	alias Democracy.Vote

	plug Democracy.Plugs.EnsureCurrentIdentity
	def is_poll(poll) do poll.kind == "custom" end
	plug Democracy.Plugs.QueryId, {:poll, Poll, "html_poll_id", &Democracy.HtmlReferenceController.is_poll/1}
	plug Democracy.Plugs.QueryId, {:reference_poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.QueryId, {:reference_poll, Poll, "html_reference_id"} when action in [:create]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:show]
	plug Democracy.Plugs.TrustMetricIds, {:trust_metric_ids, "trust_metric_url"} when action in [:show]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:show]
	plug Democracy.Plugs.FloatQuery, {:for_choice, "for_choice"}

	def index(conn, %{:poll => poll, :for_choice => for_choice, "reference_poll_id" => reference_poll_url}) do
		url = URI.parse(reference_poll_url)
		reference_poll_id =
			if url.path |> String.starts_with?("/polls/") do
				String.replace(url.path, "/polls/", "")
			else
				reference_poll_url
			end
		conn
		|> redirect to: html_poll_html_reference_path(conn, :show, poll.id, reference_poll_id, for_choice: to_string(for_choice))
	end

	def show(conn, %{:poll => poll, :user => user, :reference_poll => reference_poll, :for_choice => for_choice, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		reference = Reference.get(poll, reference_poll, for_choice)
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		results = Result.calculate(reference.approval_poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)
		reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "show.html",
			title: poll.title || "Liquio",
			reference: reference,
			for_choice: for_choice,
			own_vote: Vote.current_by(reference.approval_poll, user)
	end
end
