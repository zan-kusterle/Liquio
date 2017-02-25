defmodule Liquio.Identity do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Vote
	alias Liquio.Delegation
	alias Liquio.Node

	schema "identities" do
		field :email, :string
		field :username, :string
		field :name, :string

		field :trusts, {:map, :boolean}

		has_many :delegations_from, Liquio.Delegation, foreign_key: :from_identity_id
		has_many :delegations_to, Liquio.Delegation, foreign_key: :to_identity_id

		timestamps
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

	def preload(identity, user) do
		own_delegation = if user != nil and identity.id != user.id do
			delegation = Repo.get_by(Delegation, %{from_identity_id: user.id, to_identity_id: identity.id, is_last: true})
			if delegation != nil and delegation.data != nil do
				delegation |> Map.put(:from_identity, user) |> Map.put(:to_identity, identity)
			else
				nil
			end
		else
			nil
		end

		is_trusted = if user do Map.get(user.trusts || Map.new, identity.username) else nil end

		identity
		|> Map.put(:own_delegation, own_delegation)
		|> Map.put(:is_trusted, is_trusted)
		|> preload_delegations()
		|> preload_votes()
	end

	def preload_delegations(identity) do
		delegations_from = from(d in Delegation, where: d.from_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		|> Enum.sort_by(& &1.data.weight)

		delegations_to = from(d in Delegation, where: d.to_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		|> Enum.sort_by(& &1.data.weight)

		identity
		|> Map.put(:delegations_from, delegations_from)
		|> Map.put(:delegations_to, delegations_to)
	end

	def preload_votes(identity) do
		votes = from(v in Vote, where: v.identity_id == ^identity.id and v.is_last == true and not is_nil(v.data))
		|> Repo.all
		|> Repo.preload([:identity])

		nodes = votes
		|> Enum.group_by(& &1.key)
		|> Enum.map(fn({key, votes_for_key}) ->
			{direct_votes, reference_votes} = Enum.split_with(votes_for_key, & &1.reference_key == nil)
			references = Enum.map(reference_votes, fn(reference_vote) ->
				node = Node.from_key(reference_vote.reference_key)
				|> Map.put(:own_vote, reference_vote)
				node = node
				|> Node.preload_own_contribution(identity)
				node
				|> Map.put(:reference_result, if node.own_contribution do node.own_contribution.results else nil end)
			end)

			node = Node.from_key(key)
			|> Map.put(:own_vote, Enum.at(direct_votes, 0))
			|> Node.preload_own_contribution(identity)
			|> Map.put(:references, references)
			node
			|> Map.put(:results, if node.own_contribution do node.own_contribution.results else nil end)
		end)

		identity
		|> Map.put(:vote_nodes, nodes)
	end
end
