defmodule Liquio.Delegation do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Delegation

	schema "delegations" do
		belongs_to :from_identity, Liquio.Identity
		belongs_to :to_identity, Liquio.Identity

		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :to_datetime, Timex.Ecto.DateTime

		field :is_trusting, :boolean, default: true
		field :weight, :float, default: 1.0
		field :topics, {:array, :string}
	end

	def changeset(data, params) do
		data
		|> cast(params, ["from_identity_id", "to_identity_id"])
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

	def set(from_identity, to_identity, weight, topics) do
		remove_current_last(from_identity.id, to_identity.id)
		Repo.insert(%Delegation{
			from_identity_id: from_identity.id,
			to_identity_id: to_identity.id,
			to_datetime: nil,
			is_trusting: true,
			weight: weight,
			topics: topics
		})
	end

	def unset(from_identity, to_identity) do
		remove_current_last(from_identity.id, to_identity.id)
	end

	def remove_current_last(from_identity_id, to_identity_id) do
		now = Timex.now
		current_last = Repo.get_by(Delegation,
			from_identity_id: from_identity_id, to_identity_id: to_identity_id, to_datetime: nil)
		if current_last do
			Repo.update! Ecto.Changeset.change current_last, to_datetime: now
		end
	end

	def get_by(from_identity, to_identity) do
		Repo.get_by(Delegation, %{from_identity_id: from_identity.id, to_identity_id: to_identity.id, to_datetime: nil})
	end
	
	def get_inverse_delegations(datetime) do
		query = "SELECT DISTINCT ON (d.from_identity_id, d.to_identity_id) *
			FROM delegations AS d
			WHERE d.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}' AND (d.to_datetime >= '#{Timex.format!(datetime, "{ISO:Basic}")}' OR d.to_datetime IS NULL)
			ORDER BY d.from_identity_id, d.to_identity_id, d.datetime DESC;"
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
