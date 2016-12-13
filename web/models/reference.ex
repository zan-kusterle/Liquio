defmodule Liquio.Reference do
	use Liquio.Web, :model

	alias Liquio.Repo
	alias Liquio.Reference
	alias Liquio.Poll

	schema "references" do
		belongs_to :poll, Poll
		belongs_to :reference_poll, Poll
		belongs_to :for_choice_poll, Poll

		timestamps
	end

	def get(poll, reference_poll) do
		reference = Repo.get_by(Reference, poll_id: poll.id, reference_poll_id: reference_poll.id)
		reference =
			if reference == nil do
				for_choice_poll = Repo.insert!(%Poll{
					:kind => "is_reference",
					:choice_type => poll.choice_type,
					:title => nil,
					:topics => nil
				})
				Repo.insert!(%Reference{
					:poll => poll,
					:reference_poll => reference_poll,
					:for_choice_poll => for_choice_poll,
				})
			else
				reference
			end
		reference
	end

	def for_poll(poll, calculation_opts) do
		cache = Cachex.get!(:results_cache, {"references", poll.id})
		if cache do
			cache
		else
			references = from(d in Reference, where: d.poll_id == ^poll.id, order_by: d.inserted_at)
			|> Repo.all
			|> Repo.preload([:for_choice_poll, :reference_poll, :poll])
			|> Enum.map(fn(reference) ->
				for_choice_result = Poll.calculate(reference.for_choice_poll, calculation_opts)
				reference
				|> Map.put(:for_choice_result, for_choice_result)
			end)
			|> Enum.filter(fn(reference) ->
				reference.for_choice_result.total > 0 and reference.for_choice_result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
			end)
			|> Enum.map(fn(reference) ->
				results = Poll.calculate(reference.reference_poll, calculation_opts)
				Map.put(reference, :reference_poll, Map.put(reference.reference_poll, :results, results))
			end)
			|> Enum.sort(&(&1.reference_poll.results.total > &2.reference_poll.results.total))

			Cachex.set(:results_cache, {"references", poll.id}, references, [ttl: :timer.seconds(60)])
			references
		end
	end

	def inverse_for_poll(poll, calculation_opts) do
		cache = Cachex.get!(:results_cache, {"inverse_references", poll.id})
		if cache do
			cache
		else
			references = from(d in Reference, where: d.reference_poll_id == ^poll.id, order_by: d.inserted_at)
			|> Repo.all
			|> Repo.preload([:for_choice_poll, :reference_poll, :poll])
			|> Enum.map(fn(reference) ->
				for_choice_result = Poll.calculate(reference.for_choice_poll, calculation_opts)
				reference
				|> Map.put(:for_choice_result, for_choice_result)
			end)
			|> Enum.filter(fn(reference) ->
				reference.for_choice_result.total > 0 and reference.for_choice_result.turnout_ratio >= calculation_opts[:reference_minimum_turnout]
			end)
			|> Enum.map(fn(reference) ->
				results = Poll.calculate(reference.poll, calculation_opts)
				Map.put(reference, :poll, Map.put(reference.poll, :results, results))
			end)
			|> Enum.sort(&(&1.poll.results.total > &2.poll.results.total))

			Cachex.set(:results_cache, {"inverse_references", poll.id}, references, [ttl: :timer.seconds(60)])
			references
		end
	end
end
