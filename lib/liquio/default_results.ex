defmodule Liquio.DefaultResults do
	alias Liquio.Repo
	alias Liquio.Poll
	alias Liquio.TopicReference
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
				topics = TopicReference.for_poll(poll, calculation_opts)

				voted_topics = topics
				|> Enum.map(& Enum.join(&1, ">"))
				|> Enum.uniq

				topics_with_parents = topics
				|> Enum.flat_map(fn(topic) ->
					Enum.scan(topic.path, [], fn(path_segment, acc) ->
						acc ++ [path_segment]
					end)
				end)
				|> Enum.map(& Enum.join(&1, ">"))
				|> Enum.uniq

				results = results
				|> Map.put(:references_count, Enum.count(references))
				|> Map.put(:topics, voted_topics)
				|> Map.put(:topics_with_parents, topics_with_parents)
				Repo.update! Ecto.Changeset.change poll, latest_default_results: results
			end
		end)
	end
end