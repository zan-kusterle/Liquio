defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller
	alias Democracy.Repo
	alias Democracy.Identity
	alias Democracy.Delegation

	plug Democracy.Plugs.EnsureCurrentIdentity
	plug Democracy.Plugs.QueryId, {:identity, Identity, "html_identity_id"}
	plug Democracy.Plugs.FloatQuery, {:weight, "weight", "Delegation weight must be a number"}
	plug Democracy.Plugs.ValidateFloat, {:weight, ">=", 0, "Weight must not be negative"}
	plug Democracy.Plugs.TopicsQuery, {:topics, "topics"}

	def create(conn, %{:user => from_identity, :identity => to_identity, :weight => weight, :topics => topics}) do
		if weight > 0 do
			Delegation.set(from_identity, to_identity, weight, topics)
		else
			Delegation.unset(from_identity, to_identity)
		end
		conn
		|> redirect_back
	end
end