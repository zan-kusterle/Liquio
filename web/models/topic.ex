defmodule Liquio.Topic do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Topic
	alias Liquio.Poll

	schema "topics" do
        field :name, :string
		belongs_to :poll, Poll
		belongs_to :relevance_poll, Poll

		timestamps
	end

	def get(name, poll) do
		topic = Repo.get_by(Topic, name: name, poll_id: poll.id)
        if topic == nil do
            relevance_poll = Repo.insert!(%Poll{
                :kind => "is_topic",
                :choice_type => "probability",
                :title => nil
            })
            Repo.insert!(%Topic{
                :name => name,
                :poll => poll,
                :relevance_poll => relevance_poll
            })
        else
            topic
        end
	end

	def for_poll(poll, calculation_opts) do
		cache_key = {
			"topics",
			Float.floor(Timex.to_unix(calculation_opts.datetime) / Application.get_env(:liquio, :results_cache_seconds)),
			calculation_opts.trust_metric_url,
			calculation_opts.vote_weight_halving_days,
			poll.id
		}
		cache = Cachex.get!(:results_cache, cache_key)
		if cache do
			cache
		else
			topics = from(t in Topic, where: t.poll_id == ^poll.id, order_by: t.inserted_at)
			|> Repo.all
			|> Repo.preload([:relevance_poll, :poll])
            |> Enum.map(fn(topic) ->
                relevance_result = Poll.calculate(topic.relevance_poll, calculation_opts)
				Map.put(topic, :relevance_result, relevance_result)
			end)
            |> Enum.filter(fn(topic) ->
                # TODO: Use soft quorum t here.
                topic.relevance_result.total > 0 and topic.relevance_result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
            end)
			|> Enum.sort(&(&1.relevance_result.mean > &2.relevance_result.mean))

			Cachex.set(:results_cache, cache_key, topics, [ttl: :timer.seconds(10 * Application.get_env(:liquio, :results_cache_seconds))])
			topics
		end
	end

	def for_name(name, calculation_opts) do
		cache_key = {
			"topic_polls",
			Float.floor(Timex.to_unix(calculation_opts.datetime) / Application.get_env(:liquio, :results_cache_seconds)),
			calculation_opts.trust_metric_url,
			calculation_opts.vote_weight_halving_days,
			name
		}
		cache = Cachex.get!(:results_cache, cache_key)
		if cache do
			cache
		else
			topics = from(t in Topic, where: t.name == ^name, order_by: t.inserted_at)
			|> Repo.all
			|> Repo.preload([:relevance_poll, :poll])
            |> Enum.map(fn(topic) ->
                relevance_result = Poll.calculate(topic.relevance_poll, calculation_opts)
				Map.put(topic, :relevance_result, relevance_result)
			end)
            |> Enum.filter(fn(topic) ->
                # TODO: Use soft quorum t here.
                topic.relevance_result.total > 0 and topic.relevance_result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
            end)
			|> Enum.sort(&(&1.relevance_result.mean > &2.relevance_result.mean))

			Cachex.set(:results_cache, cache_key, topics, [ttl: :timer.seconds(10 * Application.get_env(:liquio, :results_cache_seconds))])
			topics
		end
	end
end
