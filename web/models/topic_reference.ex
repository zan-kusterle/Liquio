defmodule Liquio.TopicReference do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.TopicReference
	alias Liquio.Poll
	alias Liquio.ResultsCache

	schema "topics" do
		field :path, {:array, :string}
		belongs_to :poll, Poll
		belongs_to :relevance_poll, Poll

		timestamps
	end

	def get(path, poll) do
		topic = Repo.get_by(TopicReference, path: path, poll_id: poll.id)
        if topic == nil do
            relevance_poll = Repo.insert!(%Poll{
                :kind => "is_topic",
                :choice_type => "probability",
                :title => nil
            })
            Repo.insert!(%TopicReference{
                :path => path,
                :poll => poll,
                :relevance_poll => relevance_poll
            })
        else
            topic
        end
	end

	def for_poll(poll, calculation_opts) do
		key = {
			{"topics", poll.id, calculation_opts.datetime},
			{
				calculation_opts.trust_metric_url,
				calculation_opts.vote_weight_halving_days
			}
		}
		cache_results = ResultsCache.get(key)
		if cache_results do
			cache_results
		else
			topics = from(t in TopicReference, where: t.poll_id == ^poll.id, order_by: t.inserted_at)
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

			ResultsCache.set(key, topics)
		end
	end

	def for_path(path, calculation_opts) do
		key = {
			{"topic_polls", path, calculation_opts.datetime},
			{
				calculation_opts.trust_metric_url,
				calculation_opts.vote_weight_halving_days,
			}
		}
		cache_results = ResultsCache.get(key)
		if cache_results do
			cache_results
		else
			topics = from(t in TopicReference, where: fragment("?[1] = ?", t.path, ^Enum.at(path, 0)), order_by: t.inserted_at)
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

			ResultsCache.set(key, topics)
		end
	end
	
	def partition_visible(topics) do
		Enum.partition(topics, &is_visible/1)
	end

	def is_visible(topic) do
		Enum.count(topic.path) == 1 and String.length(Enum.at(topic.path, 0)) <= 25
	end
end
