defmodule Democracy.HtmlVoteController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result
	alias Democracy.Vote

	plug Democracy.Plugs.EnsureCurrentIdentity
	plug Democracy.Plugs.QueryId, {:poll, Poll, "html_poll_id"}
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:index]
	plug Democracy.Plugs.TrustMetricIds, {:trust_metric_ids, "trust_metric_url"} when action in [:index]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:index]
	plug Democracy.Plugs.FloatQuery, {:score, "score"} when action in [:create]


	def index(conn, %{:poll => poll, :user => user, :datetime => datetime, :vote_weight_halving_days => vote_weight_halving_days, :trust_metric_ids => trust_metric_ids}) do
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render "index.html",
			title: poll.title || "Liquio",
			poll: poll
				|> Poll.preload
				|> Map.put(:results, Result.calculate(poll, datetime, trust_metric_ids, vote_weight_halving_days, 1)),
			references:  Reference.for_poll(poll, datetime, vote_weight_halving_days, trust_metric_ids),
			own_vote: Vote.current_by(poll, user)
	end

	def create(conn, %{:poll => poll, :user => user, :score => score}) do
		{message} = if score != nil do
			if poll.choice_type == "probability" and (score < 0 or score > 1) do
				{"Choice must be between 0 and 1."}
			else
				Vote.set(poll, user, score)
				{"Your vote is now live."}
			end
		else
			Vote.delete(poll, user)
			{"You no longer have a vote in this poll."}
		end

		conn
		|> put_flash(:info, message)
		|> redirect to: html_poll_html_vote_path(conn, :index, poll.id)
	end
end