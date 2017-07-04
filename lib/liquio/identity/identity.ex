defmodule Liquio.Identity do
	use Ecto.Schema
	use Timex.Ecto.Timestamps
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Identity, Repo, Vote, ReferenceVote, Delegation, Node, Results, Signature}

	schema "identifications" do
		belongs_to :signature, Liquio.Signature
		field :username, :string
		
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :to_datetime, Timex.Ecto.DateTime

		field :key, :string
		field :name, :string
	end

	def set_identification(public_key, signature, key, name) do
		username = Identity.username_from_key(public_key)
		message = "#{username} #{key} #{name}"|> String.trim

		can_add? = if String.starts_with?(key, "http://") or String.starts_with?(key, "https://") do
			response = HTTPotion.get(key, follow_redirects: true)
			if HTTPotion.Response.success?(response) do
				String.contains?(response.body, username)
			else
				false
			end
		else
			true
		end

		if can_add? do
			signature = Signature.add!(public_key, message, signature)

			now = Timex.now
			from(v in Identity,
				where: v.username == ^username and v.key == ^key and is_nil(v.to_datetime),
				update: [set: [to_datetime: ^now]])
			|> Repo.update_all([])

			Repo.insert(%Identity{
				signature_id: signature.id,
				username: username,
				to_datetime: nil,
				key: key,
				name: name
			})
		end
	end

	def unset_identification(public_key, signature, key) do
		username = Identity.username_from_key(public_key)
		message = "#{username} #{key}" |> String.trim

		_signature = Signature.add!(public_key, message, signature)

		now = Timex.now
		from(v in Identity,
			where: v.username == ^username and v.key == ^key and is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])
	end

	def username_from_key(public_key) do
		:crypto.hash(:sha512, public_key)
		|> :binary.bin_to_list
		|> Enum.map(& <<rem(&1, 26) + 97>>)
		|> Enum.slice(0, 16)
		|> Enum.join("")
	end

	def all() do
		delegations = from(d in Delegation, where: is_nil(d.to_datetime))
		|> Repo.all
		
		delegations_by_usernames = delegations
		|> Enum.group_by(& &1.username)
		delegations_by_to_usernames = delegations
		|> Enum.group_by(& &1.to_username)
		usernames = Enum.uniq(Map.keys(delegations_by_usernames) ++ Map.keys(delegations_by_to_usernames))

		identities = usernames
		|> Enum.map(fn(username) ->
			%{
				:username => username,
				:delegations_from => delegations_by_usernames |> Map.get(username, []) |> Enum.sort_by(& &1.weight),
				:delegations_to => delegations_by_to_usernames |> Map.get(username, []) |> Enum.sort_by(& &1.weight)
			}
		end)

		identities
	end

	def preload(username) do
		%{:username => username}
		|> preload_identifications()
		|> preload_delegations()
		|> preload_votes()
	end

	def preload_identifications(identity) do
		identifications = from(i in Identity, where: i.username == ^identity.username and is_nil(i.to_datetime))
		|> Repo.all
		|> Repo.preload([:signature])

		identity
		|> Map.put(:identifications, identifications)
	end

	def preload_delegations(identity) do
		delegations_from = from(d in Delegation, where: d.username == ^identity.username and is_nil(d.to_datetime))
		|> Repo.all
		|> Repo.preload([:signature])
		|> Enum.sort_by(& &1.weight)

		delegations_to = from(d in Delegation, where: d.to_username == ^identity.username and is_nil(d.to_datetime))
		|> Repo.all
		|> Repo.preload([:signature])
		|> Enum.sort_by(& &1.weight)

		identity
		|> Map.put(:delegations_from, delegations_from)
		|> Map.put(:delegations_to, delegations_to)
	end

	def preload_votes(identity) do
		votes = from(v in Vote, where: v.username == ^identity.username and is_nil(v.to_datetime) and not is_nil(v.choice))
		|> Repo.all
		|> Enum.map(& Map.put(&1, :identity, identity))
		votes_by_path = votes |> Enum.group_by(& &1.path)
		reference_votes = from(v in ReferenceVote, where: v.username == ^identity.username and is_nil(v.to_datetime) and not is_nil(v.relevance))
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
			|> Map.put(:results, Results.from_votes(votes_for_path))
			|> Map.put(:references, references)
		end)
		
		identity
		|> Map.put(:vote_nodes, nodes)
	end
end
