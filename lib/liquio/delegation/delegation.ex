defmodule Liquio.Delegation do
	use Ecto.Schema
	use Timex.Ecto.Timestamps
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Delegation, Repo, Identity, Signature}

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

	def set(public_key, signature, to_username, is_trusting, weight, topics) do
		weight = weight * 1.0
		username = Identity.username_from_key(public_key)
		message = "#{username} #{to_username} #{if is_trusting do "true" else "false" end} #{:erlang.float_to_binary(weight, decimals: 5)} #{if topics do Enum.join(topics, ",") else "" end}"
		|> String.trim

		signature = Signature.add!(public_key, message, signature)

		now = Timex.now
		from(v in Delegation,
			where: v.username == ^username and
				v.to_username == ^to_username and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])

		Repo.insert(%Delegation{
			signature_id: signature.id,
			username: username,
			to_username: to_username,
			to_datetime: nil,
			is_trusting: is_trusting,
			weight: weight,
			topics: topics
		})
	end

	def unset(public_key, signature, to_username) do
		username = Identity.username_from_key(public_key)
		message = "#{username} #{to_username}"

		signature = Signature.add!(public_key, message, signature)

		now = Timex.now
		from(v in Delegation,
			where: v.username == ^username and
				v.to_username == ^to_username and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])
	end

	def get_by(username, to_username) do
		Repo.get_by(Delegation, %{username: username, to_username: to_username, to_datetime: nil})
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
		|> Enum.map(& {&1.to_username, &1}) |> Enum.into(%{})

		inverse_delegations
	end
end
