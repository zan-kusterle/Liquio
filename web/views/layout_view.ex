defmodule Liquio.LayoutView do
	use Liquio.Web, :view

	alias Liquio.TrustMetric

	def is_in_trust_metric?(user) do
		case TrustMetric.get(user.trust_metric_url || Liquio.TrustMetric.default_trust_metric_url()) do
			{:ok, trust_identity_ids} ->
				MapSet.member?(trust_identity_ids, to_string(user.id))
			{:error, message} ->
				false
		end
	end

end
