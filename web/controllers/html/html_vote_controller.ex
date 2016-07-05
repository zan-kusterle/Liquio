defmodule Democracy.HtmlVoteController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result

	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_overview_id"}
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"}
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"}
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"}

	def index(conn, _params) do
		IO.inspect conn.req_cookies
		case TrustMetric.get(conn.assigns.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				references = Reference.for_poll(conn.assigns.poll, conn.assigns.datetime, conn.assigns.vote_weight_halving_days, trust_identity_ids)
				results = Result.calculate(conn.assigns.poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
				poll = conn.assigns.poll |> Map.put(:results, results)
				conn
				|> render "index.html", poll: poll, references: references
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def create(conn, %{"score" => score_text}) do
		score = case Float.parse(score_text) do
			{score, _} ->
				score
			:error ->
				nil
		end

		conn
		|> redirect to: poll_overview_html_vote_path(conn, :index, conn.assigns.poll.id)
	end
end