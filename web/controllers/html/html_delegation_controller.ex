defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller

	plug Democracy.Plugs.EnsureCurrentIdentity
	plug Democracy.Plugs.QueryId, {:identity, Identity, "html_identity_id"}

	def create(conn, %{"weight" => weight, "topics" => topics}) do
		conn
	end
end