defmodule Liquio.Helpers.PollHelper do
	alias Liquio.{Repo, Identity, Poll, Topic, Vote, Reference}

	def prepare(poll, calculation_opts, current_user, opts \\ []) do
		topics = Topic.for_poll(poll, calculation_opts) |> Topic.filter_visible
		contributions = poll |> Poll.calculate_contributions(calculation_opts) |> Enum.map(fn(contribution) ->
			Map.put(contribution, :identity, Repo.get(Identity, contribution.identity_id))
		end)
		results = Poll.calculate(poll, calculation_opts)
		own_vote = if current_user do Vote.current_by(poll, current_user) else nil end

		poll = if opts[:put_references] do
			Map.put(poll, :references, Reference.for_poll(poll, calculation_opts))
		else
			poll
		end

		poll = if opts[:put_inverse_references] do
			Map.put(poll, :inverse_references, Reference.inverse_for_poll(poll, calculation_opts))
		else
			poll
		end
		
		poll |> Map.merge(%{
			:topics => topics,
			:contributions => contributions,
			:results => results,
			:own_vote => own_vote
		})
	end
end