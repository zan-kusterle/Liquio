defmodule Democracy.HtmlIdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity
	alias Democracy.Vote
	alias Democracy.Delegation

	plug Democracy.Plugs.QueryId, {:identity, Identity, "id"} when action in [:show]

	def new(conn, _params) do
		conn
		|> render "new.html"
	end

	def create(conn, params) do
		token = Identity.generate_token()
		changeset = Identity.changeset(%Identity{token: token}, params)
		case Identity.create(changeset) do
			{:ok, identity} ->
				conn
				|> Guardian.Plug.sign_in(identity)
				|> put_flash(:info, "Hello, #{identity.name}")
				|> render "credentials.html", identity: identity, token: token
			{:error, changeset} ->
				conn
				|> put_flash(:error, "Couldn't create identity")
				|> redirect to: html_identity_path(conn, :new)
		end
	end

	def show(conn, _params) do
		identity_id = conn.assigns.identity.id
		current_identity = Guardian.Plug.current_resource(conn)
		is_me = current_identity != nil and identity_id == current_identity.id
		own_is_human_vote =
			if current_identity != nil do
				vote = Repo.get_by(Vote, identity_id: current_identity.id, poll_id: conn.assigns.identity.trust_metric_poll_id, is_last: true)
				if vote != nil and vote.data == nil do vote = nil end
				vote
			else
				nil
			end

		num_votes = Repo.one(
			from(v in Vote,
			where: v.identity_id == ^identity_id
				and v.is_last == true
				and not is_nil(v.data),
			select: count(v.id))
		)

		delegations_from = from(d in Delegation, where: d.from_identity_id == ^identity_id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])

		delegations_to = from(d in Delegation, where: d.to_identity_id == ^identity_id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		
		conn
		|> render "show.html",
			title: conn.assigns.identity.name,
			identity: conn.assigns.identity,
			is_me: is_me,
			own_is_human_vote: own_is_human_vote,
			num_votes: num_votes,
			is_trusted: true,
			delegations_to: delegations_to,
			delegations_from: delegations_from
	end
end
