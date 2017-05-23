defmodule Liquio.Signature do
	use Liquio.Web, :model
	alias Liquio.{Repo, Vote, ReferenceVote, Delegation, Node, Results}

	schema "signatures" do
		field :public_key, :string
		field :data, :map
		field :data_hash, :string
		field :signature, :string
		field :datetime
		
		timestamps()
	end

	def add(public_key, data, signature) do
		data_datetime = Map.get(data, :datetime, Timex.now)

		data = Map.drop(data, :datetime)

		# verify signature, hash

		data_hash = [21, 213, 1]

		signature
	end
end
