defmodule Liquio.Identity do
	use Liquio.Web, :model
	alias Liquio.{Repo, Vote, ReferenceVote, Delegation, Node, Results}

	schema "identities" do
		field :email, :string
		field :username, :string
		field :name, :string
		
		timestamps()
	end
	
	def changeset(data, params) do
		params = if Map.has_key?(params, "username") and is_bitstring(params["username"]) do
			Map.put(params, "username", String.downcase(params["username"]))
		else
			params
		end
		params = if Map.has_key?(params, "name") and is_bitstring(params["name"]) do
			Map.put(params, "name", capitalize_name(params["name"]))
		else
			params
		end

		data
		|> cast(params, ["username", "name"])
		|> validate_required(:username)
		|> validate_required(:name)
		|> unique_constraint(:email)
		|> unique_constraint(:username)
		|> validate_length(:username, min: 3, max: 20)
		|> validate_length(:name, min: 3, max: 255)
	end

	def create(changeset) do
		changeset = changeset
		Repo.insert!(changeset)
	end

	def search(query, search_term) do
		pattern = "%#{search_term}%"
		from(i in query,
		where: ilike(i.name, ^pattern) or ilike(i.username, ^pattern),
		order_by: fragment("similarity(?, ?) DESC", i.username, ^search_term))
	end

	defp capitalize_name(name) do
		name |> String.downcase |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
	end

	def set_trust(from_identity, to_identity, is_trusting) do
		if from_identity.id != to_identity.id do
			new_trusts = Map.put(from_identity.trusts || Map.new, to_identity.username, is_trusting)
			from_identity
			|> Ecto.Changeset.change(trusts: new_trusts)
			|> Repo.update!
		end
	end

	def unset_trust(from_identity, to_identity) do
		new_trusts = Map.delete(from_identity.trusts || Map.new, to_identity.username)
		from_identity
		|> Ecto.Changeset.change(trusts: new_trusts)
		|> Repo.update!
	end

	def preload(identity) do
		identity
		|> preload_trusts()
		|> preload_delegations()
		|> preload_votes()
	end

	def preload_trusts(identity) do
		inverse_trusts = []

		identity
		|> Map.put(:trusts_to, inverse_trusts)
		|> Map.put(:trusts_from, [])
	end

	def preload_delegations(identity) do
		delegations_from = from(d in Delegation, where: d.from_identity_id == ^identity.id and is_nil(d.to_datetime))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		|> Enum.sort_by(& &1.weight)

		delegations_to = from(d in Delegation, where: d.to_identity_id == ^identity.id and is_nil(d.to_datetime))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		|> Enum.sort_by(& &1.weight)

		identity
		|> Map.put(:delegations_from, delegations_from)
		|> Map.put(:delegations_to, delegations_to)
	end

	def preload_votes(identity) do
		votes = from(v in Vote, where: v.identity_id == ^identity.id and is_nil(v.to_datetime) and not is_nil(v.choice))
		|> Repo.all
		|> Enum.map(& Map.put(&1, :identity, identity))
		votes_by_path = votes |> Enum.group_by(& &1.path)
		reference_votes = from(v in ReferenceVote, where: v.identity_id == ^identity.id and is_nil(v.to_datetime) and not is_nil(v.relevance))
		|> Repo.all
		|> Enum.map(& Map.put(&1, :identity, identity))
		reference_votes_by_path = Enum.group_by(reference_votes, & &1.path)

		nodes = votes_by_path |> Enum.map(fn({path, votes_for_path}) ->
			references = reference_votes_by_path |> Map.get(path, []) |> Enum.map(fn(reference_vote) ->
				%{
					:results => Results.from_reference_votes([reference_vote]),
					:reference_node => Node.new(reference_vote.reference_path)
				}
			end)

			node = Node.new(path)
			|> Map.put(:own_results, Results.from_votes(votes_for_path))
			|> Map.put(:references, references)

			node
			|> Map.put(:results, node.own_results)
		end)
		
		identity
		|> Map.put(:vote_nodes, nodes)
	end
end
