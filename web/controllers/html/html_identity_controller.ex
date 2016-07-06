defmodule Democracy.HtmlIdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity
	alias Democracy.Vote

	plug Democracy.Plugs.QueryId, {:identity, Identity, "id"} when action in [:show]

	def show(conn, _params) do
		current_identity = Guardian.Plug.current_resource(conn)
		own_is_human_vote =
			if current_identity != nil do
				vote = Repo.get_by(Vote, identity_id: current_identity.id, poll_id: conn.assigns.identity.trust_metric_poll_id, is_last: true)
				if vote != nil and vote.data == nil do vote = nil end
				vote
			else
				nil
			end
		
		conn
		|> render "index.html", identity: conn.assigns.identity, is_me: conn.assigns.identity.id == current_identity.id, own_is_human_vote: own_is_human_vote
	end
end