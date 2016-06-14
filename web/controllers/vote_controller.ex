defmodule Democracy.VoteController do
	use Democracy.Web, :controller
	use Guardian.Phoenix.Controller

	alias Democracy.Vote
	alias Democracy.Poll

	plug :scrub_params, "vote" when action in [:create, :update]

	def index(conn, %{"poll_id" => poll_id}, _, _) do
		poll = Repo.get(Poll, poll_id)
		if poll do
			votes = from(v in Vote, where: v.poll_id == ^poll.id and v.is_last and not is_nil(v.data))
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
				params = params |> Map.put("poll_id", poll.id) |> Map.put("identity_id", user.id)
				changeset = Vote.changeset(%Vote{}, params)
				case Vote.set(changeset) do
					{:ok, vote} ->						
						conn
						|> put_status(:created)
						|> put_resp_header("location", poll_vote_path(conn, :show, poll, vote.id))
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

	def show(conn, %{"poll_id" => poll_id, "id" => vote_id}, _, _) do
		poll = Repo.get(Poll, poll_id)
		vote = Repo.get(Vote, vote_id)
		if poll do
			if vote != nil and vote.data != nil and vote.poll_id == poll.id do
				render(conn, "show.json", vote: vote)
			else
				conn
				|> put_status(:not_found)
				|> render(Democracy.ErrorView, "error.json", message: "Vote does not exist")
			end
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end
end
