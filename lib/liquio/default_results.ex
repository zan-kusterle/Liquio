defmodule Liquio.DefaultResults do
	alias Liquio.Repo
	alias Liquio.Poll

	def update() do
		IO.puts "Updating default results"

		trust_metric_url = Liquio.TrustMetric.default_trust_metric_url()
		calculation_opts = %{
			datetime: Timex.now,
			trust_metric_url: trust_metric_url,
			trust_metric_ids: Liquio.TrustMetric.get!(trust_metric_url),
			vote_weight_halving_days: nil,
			soft_quorum_t: 0.0,
			minimum_voting_power: 0.0,
			minimum_turnout: 0.0
		}

		polls = Repo.all Poll.all
		
		Enum.each(polls, fn(poll) ->
			results = Poll.calculate(poll, calculation_opts)
			if results.count > 0 do
				Repo.update! Ecto.Changeset.change poll, latest_default_results: results
			end
		end)
	end
end