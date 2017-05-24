defmodule Liquio.Delegation do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Delegation

	schema "delegations" do
		belongs_to :signature, Liquio.Signature
		field :username, :string
		
		field :to_username, :string

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :to_datetime, Timex.Ecto.DateTime

		field :is_trusting, :boolean, default: true
		field :weight, :float, default: 1.0
		field :topics, {:array, :string}
	end

	def changeset(data, params) do
		data
		|> cast(params, ["from_identity_id", "to_identity_id", "is_trusting", "weight", "topics"])
		|> validate_required(:from_identity_id)
		|> validate_required(:to_identity_id)
		|> assoc_constraint(:from_identity)
		|> assoc_constraint(:to_identity)
	end

	def set(changeset) do
		remove_current_last(changeset.params["from_identity_id"], changeset.params["to_identity_id"])
		changeset = changeset
		|> put_change(:to_datetime, nil)
		Repo.insert(changeset)
	end

	def set(from_identity, to_identity, is_trusting, weight, topics) do
		remove_current_last(from_identity.username, to_identity.username)
		Repo.insert(%Delegation{
			username: from_identity.username,
			to_username: to_identity.username,
			to_datetime: nil,
			is_trusting: true,
			weight: weight,
			topics: topics
		})
	end

	def unset(from_identity, to_identity) do
		remove_current_last(from_identity.id, to_identity.id)
	end

	def remove_current_last(from_identity_username, to_identity_username) do
		now = Timex.now
		from(v in Delegation,
			where: v.from_identity_username == ^from_identity_username and
				v.to_identity_username == ^to_identity_username and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])
	end

	def get_by(from_identity, to_identity) do
		Repo.get_by(Delegation, %{from_identity_username: from_identity.username, to_identity_username: to_identity.username, to_datetime: nil})
	end
	
	def get_inverse_delegations(datetime) do
		query = "SELECT DISTINCT ON (d.username, d.to_username) *
			FROM delegations AS d
			WHERE d.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}' AND (d.to_datetime >= '#{Timex.format!(datetime, "{ISO:Basic}")}' OR d.to_datetime IS NULL)
			ORDER BY d.username, d.to_username, d.datetime DESC;"
		res = Ecto.Adapters.SQL.query!(Repo, query , [])
		cols = Enum.map res.columns, &(String.to_atom(&1))
		inverse_delegations = res.rows
		|> Enum.map(fn(row) ->
			delegation = struct(Liquio.Delegation, Enum.zip(cols, row))
			delegation
			|> Map.put(:topics, if delegation.topics do MapSet.new(delegation.topics) else nil end)
		end)
		|> Enum.map(& {&1.to_identity_id, &1}) |> Enum.into(%{})

		inverse_delegations
	end
end
