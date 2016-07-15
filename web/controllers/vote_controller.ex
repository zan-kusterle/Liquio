defmodule Democracy.VoteController do
	use Democracy.Web, :controller

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]}
	},
	def index(conn, %{:poll => poll}) do
		votes = from(v in Vote, where: v.poll_id == ^poll.id and v.is_last and not is_nil(v.data))
		|> Repo.all
		render(conn, "index.json", votes: votes)
	end)

	plug :scrub_params, "vote" when action in [:create]
	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def create(conn, %{:poll => poll, :user => user, "vote" => params}) do
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
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:identity => {Plugs.IdentityParamCurrentFallback, [name: "id"]}
	},
	def show(conn, %{:poll => poll, :identity => identity}) do
		vote = Repo.get_by!(Vote, identity_id: identity.id, poll_id: poll.id, is_last: true)
		if vote do
			conn |> render("show.json", vote: vote)
		else
			conn |> put_status(:not_found)
		end
	end)

	with_params(%{
		:poll => {Plugs.ItemParam, [schema: Poll, name: "poll_id"]},
		:user => {Plugs.CurrentUser, [require: true]}
	},
	def delete(conn, %{:poll => poll, :user => user}) do
		vote = Vote.delete(poll, user)
		render(conn, "show.json", vote: vote)
	end)
end
