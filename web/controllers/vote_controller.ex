defmodule Democracy.VoteController do
	use Democracy.Web, :controller
	use Guardian.Phoenix.Controller

	alias Democracy.Vote
	alias Democracy.Poll

	plug :scrub_params, "vote" when action in [:create, :update]

	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_id"}
	def is_vote(conn, vote), do: vote.data != nil and conn.assigns.poll.id == vote.poll_id
	plug Democracy.Plugs.QueryId, {:vote, Vote, "id", &Democracy.VoteController.is_vote/2} when action in [:show]
	plug Democracy.Plugs.EnsureCurrentIdentity when action in [:create]

	def index(conn, _params, _, _) do
		votes = from(v in Vote, where: v.poll_id == ^conn.assigns.poll.id and v.is_last and not is_nil(v.data))
		|> Repo.all
		render(conn, "index.json", votes: votes)
	end

	def create(conn, %{"vote" => params}, user, claims) do
		params = params |> Map.put("poll_id", conn.assigns.poll.id) |> Map.put("identity_id", conn.assigns.user.id)
		changeset = Vote.changeset(%Vote{}, params)
		case Vote.set(changeset) do
			{:ok, vote} ->						
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_vote_path(conn, :show, conn.assigns.poll, vote.id))
				|> render("show.json", vote: vote)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, _params, _, _) do
		render(conn, "show.json", vote: conn.assigns.vote)
	end
end
