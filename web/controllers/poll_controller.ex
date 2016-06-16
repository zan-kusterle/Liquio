defmodule Democracy.PollController do
	use Democracy.Web, :controller
	use Guardian.Phoenix.Controller

	alias Democracy.Poll
	alias Democracy.Vote
	alias Democracy.Result
	alias Democracy.TrustMetric

	plug :scrub_params, "poll" when action in [:create]

	def create(conn, %{"poll" => params}, _, _) do
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

	def show(conn, %{"id" => id}, _, _) do
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

	# TODO: Maybe send preferences (trust metric url and vote weight halving days) as query params. It makes API more friendly to other services.
	# Also allows users to set preferences client side, without having an account.
	# Also allow datetime query parameter to be sent, this enables users to view results at specified point in time.
	# Same in ReferenceController
	def results(conn, %{"poll_id" => id}, user, _) do
		trust_metric_url =
			if user != nil and user.trust_metric_url != nil do
				user.trust_metric_url
			else
				TrustMetric.default_trust_metric_url()
			end
		vote_weight_halving_days = if user do user.vote_weight_halving_days else nil end

		poll = Repo.get!(Poll, id)
		results = Result.calculate(poll, Ecto.DateTime.utc(), TrustMetric.get(trust_metric_url), vote_weight_halving_days)
		conn
		|> render("results.json", results: results)
	end

	def results_by_time() do
		# TODO
	end
end
