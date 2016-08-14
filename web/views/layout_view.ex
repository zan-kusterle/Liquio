defmodule Liquio.LayoutView do
	use Liquio.Web, :view

	alias Liquio.TrustMetric

	def is_in_trust_metric?(conn) do
		user = Guardian.Plug.current_resource(conn)
		{url, trust_identity_ids} = Liquio.Controllers.Helpers.get_trust_identity_ids(conn)
		MapSet.member?(trust_identity_ids, to_string(user.id))
	end
end
