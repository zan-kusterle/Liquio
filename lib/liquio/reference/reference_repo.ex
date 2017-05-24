defmodule Liquio.ReferenceRepo do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Node, Delegation, NodeRepo, Reference, ReferenceVote, Results, VotingPower}

	def load(reference, calculation_opts) do
		reference = reference
		|> load_results(calculation_opts)
		|> Map.put(:node, Node.new(reference.path) |> NodeRepo.load(calculation_opts, 0))
		|> Map.put(:reference_node, Node.new(reference.reference_path) |> NodeRepo.load(calculation_opts, 0))
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