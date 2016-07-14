defmodule Democracy.HtmlDelegationController do
	use Democracy.Web, :controller
	alias Democracy.Repo
	alias Democracy.Identity
	alias Democracy.Delegation

	plug Democracy.Plugs.EnsureCurrentIdentity
	plug Democracy.Plugs.QueryId, {:identity, Identity, "html_identity_id"}

	def create(conn, %{"weight" => weight, "topics" => topics}) do
		topics = topics |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.filter(& String.length(&1) > 0)
		case Float.parse(weight) do
			{weight, _} ->
				if weight > 0 do
					delegation = Delegation.set(conn.assigns.user, conn.assigns.identity, weight, topics)
				else
					delegation = Repo.get_by(Delegation, %{from_identity_id: conn.assigns.user.id, to_identity_id: conn.assigns.identity.id, is_last: true})
					if delegation do
						Delegation.unset(conn.assigns.user, conn.assigns.identity)
					end
				end
			:error ->
				conn = conn
				|> put_flash(:error, "Delegation weight must be a number")
		end

		conn
        |> redirect to: html_identity_path(conn, :show, conn.assigns.identity.id)
	end
end