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
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				references = Reference.for_poll(conn.assigns.poll, conn.assigns.datetime, conn.assigns.vote_weight_halving_days, trust_identity_ids)
				results = Result.calculate(conn.assigns.poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
				poll = conn.assigns.poll |> Map.put(:results, results)
				vote = Repo.get_by(Vote, identity_id: conn.assigns.user.id, poll_id: conn.assigns.poll.id, is_last: true)
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
				Vote.set(conn.assigns.poll, conn.assigns.user, score)
				{"Your vote has been counted"}
			:error ->
				Vote.delete(conn.assigns.poll, conn.assigns.user)
				{"Your vote has been removed"}
		end

		conn
		|> put_flash(:info, message)
		|> redirect to: html_poll_html_vote_path(conn, :index, conn.assigns.poll.id)
	end
end