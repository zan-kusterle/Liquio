defmodule Democracy.PollController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Vote
	alias Democracy.Result
	alias Democracy.TrustMetric

	plug :scrub_params, "poll" when action in [:create]

	def create(conn, %{"poll" => params}) do
		changeset = Poll.changeset(%Poll{}, params)
		case Poll.create(changeset) do
			{:ok, poll} ->
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_path(conn, :show, poll))
				|> render("show.json", poll: poll)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, %{"id" => id}) do
		poll = Repo.get(Poll, id)
		if poll do
			conn
			|> render("show.json", poll: poll)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end
	
	def results(conn, params = %{"poll_id" => id}) do
		trust_metric_url = Map.get(params, "trust_metric_url") || TrustMetric.default_trust_metric_url()
		vote_weight_halving_days =
			if Map.get(params, "vote_weight_halving_days") do
				{value, _} = Integer.parse(params["vote_weight_halving_days"])
				value
			else
				nil
			end
		datetime =
			if Map.get(params, "datetime") do
				Ecto.DateTime.cast!(params["datetime"])
			else
				Ecto.DateTime.utc()
			end
		
		poll = Repo.get(Poll, id)
		if poll do
			case TrustMetric.get(trust_metric_url) do
				{:ok, trust_identity_ids} ->
					results = Result.calculate(poll, datetime, trust_identity_ids, vote_weight_halving_days)
					conn
					|> render("results.json", results: results)
				{:error, message} ->
					conn
					|> put_status(:not_found)
					|> render(Democracy.ErrorView, "error.json", message: message)
			end
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end

	def results_by_time() do
		# TODO
	end
end
