defmodule Liquio.DefaultResults do
	alias Liquio.Repo
	alias Liquio.Poll
	alias Liquio.Topic
	alias Liquio.Reference

	def update() do
		IO.puts "Updating default results"

		trust_metric_url = Liquio.TrustMetric.default_trust_metric_url()
		calculation_opts = %{
			datetime: Timex.now,
			trust_metric_url: trust_metric_url,
			trust_metric_ids: Liquio.TrustMetric.get!(trust_metric_url),
			vote_weight_halving_days: nil,
			minimum_voting_power: 0.0,
			minimum_turnout: 0.0,
			reference_minimum_agree: 0.5,
			reference_minimum_turnout: 0.0
		}

		polls = Repo.all Poll.all
		
		Enum.each(polls, fn(poll) ->
			results = Poll.calculate(poll, calculation_opts)
			if results.total > 0 do
				references = Reference.for_poll(poll, calculation_opts)
				topics = Topic.for_poll(poll, calculation_opts)
				|> Enum.map(& &1.name)
				results = results
				|> Map.put(:references_count, Enum.count(references))
				|> Map.put(:topics, topics)
				Repo.update! Ecto.Changeset.change poll, latest_default_results: results
			end
		end)
	end
end