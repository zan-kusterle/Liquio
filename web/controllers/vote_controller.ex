defmodule Democracy.VoteController do
	use Democracy.Web, :controller

	alias Democracy.Vote
	alias Democracy.Poll

	plug :scrub_params, "vote" when action in [:create, :update]

	plug Democracy.Plugs.QueryId, {:poll, Poll, "poll_id"}
	plug Democracy.Plugs.QueryIdentityIdFallbackCurrent, {:identity, "id"} when action in [:show]
	plug Democracy.Plugs.EnsureCurrentIdentity when action in [:create, :delete]

	def index(conn, _params) do
		votes = from(v in Vote, where: v.poll_id == ^conn.params.poll.id and v.is_last and not is_nil(v.data))
		|> Repo.all
		render(conn, "index.json", votes: votes)
	end

	def create(conn, %{"vote" => params}) do
		params = params |> Map.put("poll_id", conn.params.poll.id) |> Map.put("identity_id", conn.params.user.id)
		changeset = Vote.changeset(%Vote{}, params)
		case Vote.set(changeset) do
			{:ok, vote} ->						
				conn
				|> put_status(:created)
				|> put_resp_header("location", poll_vote_path(conn, :show, conn.params.poll, vote.id))
				|> render("show.json", vote: vote)
			{:error, changeset} ->
				conn
				|> put_status(:unprocessable_entity)
				|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, _params) do
		vote = Repo.get_by!(Vote, identity_id: conn.params.identity.id, poll_id: conn.params.poll.id, is_last: true)
		if vote do
			conn |> render("show.json", vote: vote)
		else
			conn |> put_status(:not_found)
		end
	end

	def delete(conn, _params) do
		vote = Vote.delete(conn.params.poll, conn.params.user)
		render(conn, "show.json", vote: vote)
	end
end
