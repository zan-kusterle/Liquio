defmodule Democracy.Result do
	use Democracy.Web, :model

	alias Democracy.Repo

	schema "results" do
		belongs_to :poll, Democracy.Poll
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :data, :map
	end

	def calculate(poll, trust_metric_key, datetime) do
		votes = Repo.all(Vote, poll_id: poll.id)
		votes_by_choice = Enum.group_by(votes, &(&1.choice))

		Enum.map(poll.choices, fn(choice) ->
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
	end
end

# t(result) = #delegations
# t(select) + #votes * t(result)
# 1 way is to have time graph only with default trust metric from cache
# calculate result at N times, N * (t(select) + t(result))
# another way is to send needed data to client (all relevant users and delegations and votes). 1M delegations * (4B, 3B, 3B, 1B) + 100K votes * (4B, 3B, 1B * # choices) = 1M * 11B + 100K * 10B = 12MB

"""
SELECT d.from_identity_id, d.to_identity_id, d.weight
FROM (
	SELECT *
	FROM delegations
	WHERE datetime < t
	ORDER BY datetime DESC
) AS d
JOIN trust_metrics AS t ON t.key = 1 AND d.from_identity_id = t.identity_id
GROUP BY d.from_identity_id;
HAVING d.data IS NOT NULL;

SELECT v.identity_id, v.choice, v.score
FROM (
	SELECT *
	FROM votes
	WHERE datetime < t
	ORDER BY datetime DESC
) AS v
JOIN trust_metrics AS t ON t.key = 1 AND v.identity_id = t.identity_id
WHERE v.poll_id = 1
GROUP BY v.identity_id, v.choice
HAVING v.data IS NOT NULL;
"""