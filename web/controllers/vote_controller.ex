defmodule Democracy.VoteController do
	use Democracy.Web, :controller
	use Guardian.Phoenix.Controller

	alias Democracy.Vote
	alias Democracy.Poll

	plug :scrub_params, "vote" when action in [:create, :update]

	def index(conn, %{"poll_id" => poll_id}, _, _) do
		poll = Repo.get(Poll, poll_id)
		if poll do
			votes = from(v in Vote, where: v.poll_id == ^poll.id)
			|> Repo.all
			render(conn, "index.json", votes: votes)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end

	def create(conn, %{"poll_id" => poll_id, "vote" => params}, user, claims) do
		poll = Repo.get(Poll, poll_id)
		if poll do
			if user do
				params = params |> Map.put("poll_id", poll.id) |> Map.put("user_id", user.id)
				changeset = Vote.changeset(params)
				case Repo.insert(params) do
					{:ok, vote} ->
						spawn_link(Result.on_vote_cast(vote))
						
						conn
						|> put_status(:created)
						|> put_resp_header("location", poll_vote_path(conn, :show, poll, vote))
						|> render("show.json", vote: vote)
					{:error, changeset} ->
						conn
						|> put_status(:unprocessable_entity)
						|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
				end
			else
				conn
				|> send_resp(:unauthorized, "No current user")
			end
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end
end
