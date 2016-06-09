defmodule Democracy.VoteController do
	use Democracy.Web, :controller
	use Guardian.Phoenix.Controller

	alias Democracy.Vote
	alias Democracy.Poll

	plug :scrub_params, "vote" when action in [:create, :update]

	def index(conn, %{"poll_id" => poll_id}, _, _) do
		votes = Repo.all(Vote, poll_id: poll_id)
		render(conn, "index.json", votes: votes)
	end

	def create(conn, %{"poll_id" => poll_id, "vote" => %{"choice" => choice, "score" => score}}, user, claims) do
		poll = Repo.get!(Poll, poll_id)
		case Repo.insert(Vote.new(user, poll, choice, score * 1.0)) do
			{:ok, vote} ->
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_vote_path(conn, :show, poll, vote))
				|> render("show.json", vote: vote)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end
end
