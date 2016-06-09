defmodule Democracy.PollController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Vote

	plug :scrub_params, "poll" when action in [:create, :update]

	def create(conn, %{"poll" => params}) do
		
	end

	def show(conn, %{"id" => id}) do
		poll = Repo.get!(Poll, id)
		render(conn, "show.json", poll: poll)
	end

	def results(conn, %{"poll_id" => id}) do
		poll = Repo.get!(Poll, id)
		votes = Repo.all(Vote, poll_id: poll.id)

		votes_by_choice = Enum.group_by(votes, &(&1.choice))
		results = Enum.map(poll.choices, fn(choice) ->
			votes_for_choice = Map.get(votes_by_choice, choice, [])
			count = Enum.count(votes_for_choice)
			contributions_by_identities = Enum.map(votes_for_choice, fn(vote) ->
				voting_power = if poll.is_direct do
					1
				else
					1
				end
				%{
					:identity_id => vote.identity_id,
					:contribution => voting_power * vote.score
				}
			end)
			total = Enum.sum(Enum.map(contributions_by_identities, & &1.contribution))
			mean = total / count
			%{
				:choice => choice,
				:mean => mean,
				:total => total,
				:count => count,
				:contributions_by_identities => contributions_by_identities
			}
		end)
		render(conn, "results.json", results: results)
	end
end
