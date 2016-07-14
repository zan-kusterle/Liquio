defmodule Democracy.HtmlReferenceController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Reference
	alias Democracy.TrustMetric
	alias Democracy.Result
	alias Democracy.Vote

	plug Democracy.Plugs.EnsureCurrentIdentity
	plug Democracy.Plugs.QueryId, {:poll, Poll, "html_poll_id"}
	plug Democracy.Plugs.QueryId, {:reference_poll, Poll, "id"} when action in [:show]
	plug Democracy.Plugs.QueryId, {:reference_poll, Poll, "html_reference_id"} when action in [:create]
	plug Democracy.Plugs.Datetime, {:datetime, "datetime"} when action in [:show]
	plug Democracy.Plugs.TrustMetricUrl, {:trust_metric_url, "trust_metric_url"} when action in [:show]
	plug Democracy.Plugs.VoteWeightHalvingDays, {:vote_weight_halving_days, "vote_weight_halving_days"} when action in [:show]
	plug Democracy.Plugs.FloatQuery, {:for_choice, "for_choice"}

	def index(conn, %{"reference_poll_id" => reference_poll_url}) do
		url = URI.parse(reference_poll_url)
		reference_poll_id =
			if url.path |> String.starts_with?("/polls/") do
				String.replace(url.path, "/polls/", "")
			else
				reference_poll_url
			end

		conn
		|> redirect to: html_poll_html_reference_path(conn, :show, conn.params.poll.id, reference_poll_id, for_choice: to_string(conn.params.for_choice))
	end

	def show(conn, _params) do
		case TrustMetric.get(conn.params.trust_metric_url) do
			{:ok, trust_identity_ids} ->
				reference = Reference.get(conn.params.poll, conn.params.reference_poll, conn.params.for_choice)
				|> Repo.preload([:approval_poll, :reference_poll, :poll])
				if reference.poll.kind == "custom" do
					results = Result.calculate(reference.approval_poll, conn.params.datetime, trust_identity_ids, conn.params.vote_weight_halving_days, 1)
					reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
					vote = Repo.get_by(Vote, identity_id: conn.params.user.id, poll_id: reference.approval_poll.id, is_last: true)
					if vote != nil and vote.data == nil do vote = nil end
					conn
					|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
					|> render("show.html", title: reference.poll.title, reference: reference, for_choice: conn.params.for_choice, own_vote: vote)
				else
					conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: "Does not exist")
				end
				
			{:error, message} ->
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: message)
		end
	end

	def create(conn, %{"score" => score_text}) do
		reference = Reference.get(conn.params.poll, conn.params.reference_poll, conn.params.for_choice)
		|> Repo.preload([:approval_poll, :reference_poll, :poll])

		{message} = case Float.parse(score_text) do
			{score, _} ->
				Vote.set(reference.approval_poll, conn.params.user, score)
				{"Your vote is now live."}
			:error ->
				Vote.delete(reference.approval_poll, conn.params.user)
				{"You no longer have a vote in this poll."}
		end

		conn
		|> put_flash(:info, message)
		|> redirect to: html_poll_html_reference_path(conn, :show, conn.params.poll.id, conn.params.reference_poll.id, for_choice: to_string(conn.params.for_choice))
	end
end
