defmodule Liquio.DelegationData do
	use Liquio.Web, :model

	embedded_schema do
		field :weight, :float, default: 1.0
		field :topics, {:array, :string}
	end

	def changeset(data, params) do
		params = if is_integer(params["weight"]) do
			Map.put(params, "weight", params["weight"] * 1.0)
		else
			params
		end
		data
		|> cast(params, ["weight", "topics"])
		|> validate_number(:weight, greater_than: 0)
	end
end

defmodule Liquio.Delegation do
	use Liquio.Web, :model

	alias Liquio.DelegationData
	alias Liquio.Repo
	alias Liquio.Delegation

	schema "delegations" do
		belongs_to :from_identity, Liquio.Identity
		belongs_to :to_identity, Liquio.Identity

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		embeds_one :data, DelegationData
	end

	def changeset(data, params) do
		data
		|> cast(params, ["from_identity_id", "to_identity_id"])
		|> validate_required(:from_identity_id)
		|> validate_required(:to_identity_id)
		|> assoc_constraint(:from_identity)
		|> assoc_constraint(:to_identity)
		|> put_embed(:data, DelegationData.changeset(%DelegationData{}, params))
	end

	def set(changeset) do
		remove_current_last(changeset.params["from_identity_id"], changeset.params["to_identity_id"])
		changeset = changeset
		|> put_change(:is_last, true)
		Repo.insert(changeset)
	end

	def set(from_identity, to_identity, weight, topics) do
		remove_current_last(from_identity.id, to_identity.id)
		Repo.insert(%Delegation{
			from_identity_id: from_identity.id,
			to_identity_id: to_identity.id,
			is_last: true,
			data: %DelegationData{
				weight: weight,
				topics: topics
			}
		})
	end

	def unset(from_identity, to_identity) do
		delegation = Repo.get_by(Delegation, %{from_identity_id: from_identity.id, to_identity_id: to_identity.id, is_last: true})
		if delegation != nil do
			remove_current_last(from_identity.id, to_identity.id)
			Repo.insert(%Delegation{
				from_identity_id: from_identity.id,
				to_identity_id: to_identity.id,
				is_last: true,
				data: nil
			})
		end
	end

	def remove_current_last(from_identity_id, to_identity_id) do
		current_last = Repo.get_by(Delegation,
			from_identity_id: from_identity_id, to_identity_id: to_identity_id, is_last: true)
		if current_last do
			Repo.update! Ecto.Changeset.change current_last, is_last: false
		end
	end

	def get_by(from_identity, to_identity) do
		Repo.get_by(Delegation, %{from_identity_id: from_identity.id, to_identity_id: to_identity.id, is_last: true})
	end
end