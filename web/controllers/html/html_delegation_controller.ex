defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller
	alias Democracy.Repo
	alias Democracy.Identity
	alias Democracy.Delegation

	plug Democracy.Plugs.EnsureCurrentIdentity
	plug Democracy.Plugs.QueryId, {:identity, Identity, "html_identity_id"}
	plug Democracy.Plugs.FloatQuery, {:weight, "weight", "Delegation weight must be a number"}
	plug Democracy.Plugs.TopicsQuery, {:topics, "topics"}
	plug Democracy.Plugs.RedirectBack

	def create(conn, %{:user => from_identity, :identity => to_identity, :weight => weight, :topics => topics}) do
		if weight > 0 do
			Delegation.set(from_identity, to_identity, weight, topics)
		else
			Delegation.unset(from_identity, to_identity)
		end
	end
end