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

	def index(conn, %{"reference_poll_id" => reference_poll_url, "pole" => pole}) do
		url = URI.parse(reference_poll_url)
		reference_poll_id =
			if url.path |> String.starts_with?("/polls/") do
				String.replace(url.path, "/polls/", "")
			else
				reference_poll_url
			end

		conn
		|> redirect to: html_poll_html_reference_path(conn, :show, conn.assigns.poll.id, reference_poll_id, pole: pole)
	end

	def show(conn, %{"pole" => pole}) do
		if pole == "positive" or pole == "negative" do
			case TrustMetric.get(conn.assigns.trust_metric_url) do
				{:ok, trust_identity_ids} ->
					reference = Reference.get(conn.assigns.poll, conn.assigns.reference_poll, pole)
					|> Repo.preload([:approval_poll, :reference_poll, :poll])
					results = Result.calculate(reference.approval_poll, conn.assigns.datetime, trust_identity_ids, conn.assigns.vote_weight_halving_days, 1)
					reference = Map.put(reference, :approval_poll, Map.put(reference.approval_poll, :results, results))
					vote = Repo.get_by(Vote, identity_id: conn.assigns.user.id, poll_id: reference.approval_poll.id, is_last: true)
					if vote != nil and vote.data == nil do vote = nil end
					conn
					|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
					|> render("show.html", title: reference.poll.title, reference: reference, pole: pole, own_vote: vote)
				{:error, message} ->
					conn
					|> put_status(:not_found)
					|> render(Democracy.ErrorView, "error.json", message: message)
			end
		else
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Pole must be positive or negative")
		end
	end

	def create(conn, %{"pole" => pole, "score" => score_text}) do
		if pole == "positive" or pole == "negative" do
			reference = Reference.get(conn.assigns.poll, conn.assigns.reference_poll, pole)
			|> Repo.preload([:approval_poll, :reference_poll, :poll])

			{message} = case Float.parse(score_text) do
				{score, _} ->
					Vote.set(reference.approval_poll, conn.assigns.user, score)
					{"Your vote has been counted"}
				:error ->
					Vote.delete(reference.approval_poll, conn.assigns.user)
					{"Your vote has been removed"}
			end

			conn
			|> put_flash(:info, message)
			|> redirect to: html_poll_html_reference_path(conn, :show, conn.assigns.poll.id, conn.assigns.reference_poll.id, pole: pole)
		else
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Pole must be positive or negative")
		end		
	end
end