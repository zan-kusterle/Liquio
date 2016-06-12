defmodule Democracy.TrustMetric do
	use Democracy.Web, :model

	schema "trust_metrics" do
		field :identity, :string
		field :key, :string
	end
end
