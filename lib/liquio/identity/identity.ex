defmodule Liquio.Identity do
	use Liquio.Web, :model
	alias Liquio.{Repo, Vote, ReferenceVote, Delegation, Node, Results}

	def username_from_key(public_key) do
		:crypto.hash(:sha512, public_key)
		|> :binary.bin_to_list
		|> Enum.map(& <<rem(&1, 26) + 97>>)
		|> Enum.slice(0, 16)
		|> Enum.join("")
	end

	def preload(username) do
		%{:username => username}
		|> preload_delegations()
		|> preload_votes()
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
