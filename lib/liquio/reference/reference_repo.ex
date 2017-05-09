defmodule Liquio.ReferenceRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Node, Delegation, NodeRepo, Reference, ReferenceVote, Results, VotingPower}

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
end