defmodule Liquio.Helpers.PollHelper do
	alias Liquio.{Repo, Identity, Poll, Topic, Vote, Reference}

	def prepare(poll, calculation_opts, current_user, opts \\ []) do
		poll = if opts[:from_default_cache] do
			if poll.latest_default_results do
				results = Liquio.Poll.unserialize_results(poll.latest_default_results)
				topics = poll.latest_default_results["topics"] |> Enum.map(& %{:name => &1})
				poll |> Map.merge(%{
					:topics => topics,
					:contributions => nil,
					:results => results
				})
			else
				poll |> Map.merge(%{
					:topics => [],
					:contributions => nil,
					:results => nil
				})
			end
		else
			topics = Topic.for_poll(poll, calculation_opts) |> Topic.filter_visible
			contributions = poll |> Poll.calculate_contributions(calculation_opts) |> Enum.map(fn(contribution) ->
				Map.put(contribution, :identity, Repo.get(Identity, contribution.identity_id))
			end)
			results = Poll.calculate(poll, calculation_opts)
			poll |> Map.merge(%{
				:topics => topics,
				:contributions => contributions,
				:results => results
			})
		end
		
		own_vote = if current_user do Vote.current_by(poll, current_user) else nil end
		poll = Map.put(poll, :own_vote, own_vote)

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
		
		poll
	end
end