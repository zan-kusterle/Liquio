defmodule Democracy.HtmlVoteController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result
	alias Democracy.Vote

	plug Democracy.Plugs.EnsureCurrentIdentity
	plug Democracy.Plugs.QueryId, {:poll, Poll, "html_poll_id"}
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"}
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"}
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"}

	def index(conn, _params) do
		case TrustMetric.get(conn.params.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				references = Reference.for_poll(conn.params.poll, conn.params.datetime, conn.params.vote_weight_halving_days, trust_identity_ids)
				results = Result.calculate(conn.params.poll, conn.params.datetime, trust_identity_ids, conn.params.vote_weight_halving_days, 1)
				poll = conn.params.poll
				|> Map.put(:results, results)
				|> Map.put(:title, Poll.title(conn.params.poll))
				vote = Repo.get_by(Vote, identity_id: conn.params.user.id, poll_id: conn.params.poll.id, is_last: true)
				if vote != nil and vote.data == nil do vote = nil end
				conn
				|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
				|> render "index.html", title: poll.title, poll: poll, references: references, own_vote: vote
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def create(conn, %{"score" => score_text}) do
		{message} = case Float.parse(score_text) do
			{score, _} ->
				if conn.params.poll.choice_type == "probability" and (score < 0 or score > 1) do
					{"Choice must be between 0 and 1."}
				else
					Vote.set(conn.params.poll, conn.params.user, score)
					{"Your vote is now live."}
				end
			:error ->
				Vote.delete(conn.params.poll, conn.params.user)
				{"You no longer have a vote in this poll."}
		end

		conn
		|> put_flash(:info, message)
		|> redirect to: html_poll_html_vote_path(conn, :index, conn.params.poll.id)
	end
end