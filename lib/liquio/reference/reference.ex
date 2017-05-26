defmodule Liquio.Reference do
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Node, Delegation, Reference, ReferenceVote, Results, VotingPower}
	
	@enforce_keys [:path, :reference_path, :results]
	defstruct [:path, :reference_path, :results]

	def new(path, reference_path) do
		%Liquio.Reference{path: path, reference_path: reference_path, results: nil}
	end

	def path_from_key(key) do
		key |> String.trim(" ") |> String.split("/")
	end

	def decode(key, reference_key) do
		%Reference{
			path: path_from_key(key),
			reference_path: path_from_key(reference_key),
			results: nil
		}
	end

	def group_key(reference) do
		"#{Enum.join(reference.path, "/") |> String.downcase} -> #{Enum.join(reference.reference_path, "/") |> String.downcase}" |> String.downcase
	end

	def load(reference, calculation_opts) do
		reference = reference
		|> load_results(calculation_opts)
		|> Map.put(:node, Node.new(reference.path) |> Node.load(calculation_opts, 0))
		|> Map.put(:reference_node, Node.new(reference.reference_path) |> Node.load(calculation_opts, 0))
	end
	
	def load_results(reference, calculation_opts) do
		votes = ReferenceVote.get_at_datetime(reference.path, reference.reference_path, calculation_opts.datetime) |> Repo.preload([:signature])
		inverse_delegations = Delegation.get_inverse_delegations(calculation_opts.datetime)
		results = Results.from_reference_votes(votes, inverse_delegations, calculation_opts)

		reference
		|> Map.put(:results, results)
		|> Map.put(:calculation_opts, calculation_opts)
	end
end
