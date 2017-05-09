defmodule Liquio.ReferenceRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Delegation, Node, NodeRepo, Reference, ReferenceVote, Results, VotingPower}

	def load(reference, calculation_opts) do
		load(reference, calculation_opts, nil)
	end
	def load(reference, calculation_opts, user) do
		reference = reference
		|> load_results(calculation_opts)
		|> Map.put(:node, Node.new(reference.path) |> NodeRepo.load(calculation_opts, user, 0))
		|> Map.put(:reference_node, Node.new(reference.reference_path) |> NodeRepo.load(calculation_opts, user, 0))
			
		own_vote = if Map.has_key?(reference, :own_vote) do
			reference.own_vote
		else
			if user do ReferenceVote.current_by(user, reference) else nil end
		end
		own_results = if own_vote do
			own_vote = own_vote |> Repo.preload([:identity])
			Results.from_reference_votes([own_vote])
		else
			nil
		end

		reference
		|> Map.put(:own_vote, own_vote)
		|> Map.put(:own_results, own_results)
	end
	
	def load_results(reference, calculation_opts) do
		votes = ReferenceVote.get_at_datetime(reference.path, reference.reference_path, calculation_opts.datetime) |> Repo.preload([:identity])
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		results = Results.from_reference_votes(votes, inverse_delegations, calculation_opts)

		reference
		|> Map.put(:results, results)
		|> Map.put(:calculation_opts, calculation_opts)
	end
	
	def get_references(node, calculation_opts) do
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)

		ReferenceVote.get_at_datetime(node.path, nil, calculation_opts.datetime)
		|> Repo.preload([:identity])
		|> Enum.group_by(& &1.reference_path)
		|> prepare_reference_nodes(inverse_delegations, calculation_opts)
		|> Enum.map(fn({reference_path, result}) ->
			Reference.new(node.path, reference_path)
			|> Map.put(:results, result)
			|> Map.put(:node, node)
		end)
		|> Enum.sort_by(& -&1.results.average)
	end
	
	def get_inverse_references(node, calculation_opts) do
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)

		ReferenceVote.get_at_datetime(nil, node.path, calculation_opts.datetime)
		|> Repo.preload([:identity])
		|> Enum.group_by(& &1.path)
		|> prepare_reference_nodes(inverse_delegations, calculation_opts)
		|> Enum.map(fn({path, result}) ->
			Reference.new(path, node.path)
			|> Map.put(:results, result)
			|> Map.put(:reference_node, node)
		end)
		|> Enum.sort_by(& -&1.results.average)
	end

	defp prepare_reference_nodes(keys_with_votes, inverse_delegations, calculation_opts) do
		keys_with_votes
		|> Enum.map(fn({k, votes}) ->
			{k, Results.from_reference_votes(votes, inverse_delegations, calculation_opts)}
		end)
		|> Enum.filter(fn({_k, result}) ->
			result.voting_power > 0 and result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
		end)
	end
end