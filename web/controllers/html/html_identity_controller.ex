defmodule Democracy.HtmlIdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity
	alias Democracy.Vote

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
		current_identity = Guardian.Plug.current_resource(conn)
		is_me = current_identity != nil and conn.assigns.identity.id == current_identity.id
		own_is_human_vote =
			if current_identity != nil do
				vote = Repo.get_by(Vote, identity_id: current_identity.id, poll_id: conn.assigns.identity.trust_metric_poll_id, is_last: true)
				if vote != nil and vote.data == nil do vote = nil end
				vote
			else
				nil
			end
		
		conn
		|> render "index.html", identity: conn.assigns.identity, is_me: is_me, own_is_human_vote: own_is_human_vote
	end
end