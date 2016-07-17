defmodule Democracy.Reference do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.Reference
	alias Democracy.Poll
	alias Democracy.Result

	schema "references" do
		belongs_to :poll, Poll
		belongs_to :reference_poll, Poll
		belongs_to :approval_poll, Poll
		field :for_choice, :float

		timestamps
	end

	def get(poll, reference_poll, for_choice) do
		reference = Repo.get_by(Reference, poll_id: poll.id, reference_poll_id: reference_poll.id, for_choice: for_choice)
		if reference == nil do
			approval_poll = Repo.insert!(%Poll{
				:kind => "is_reference",
				:choice_type => "probability",
				:title => nil,
				:topics => nil
			})
			reference = Repo.insert!(%Reference{
				:poll => poll,
				:reference_poll => reference_poll,
				:approval_poll => approval_poll,
				:for_choice => for_choice
			})
		end
		reference
	end

	def for_poll(poll, calculation_opts) do
		from(d in Reference, where: d.poll_id == ^poll.id, order_by: d.inserted_at)
		|> Repo.all
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		|> Enum.filter(fn(reference) ->
			approval_result = Result.calculate(reference.approval_poll, calculation_opts)
			approval_result.mean >= calculation_opts[:minimum_reference_approval_score]
		end)
		|> Enum.map(fn(reference) ->
			results = Result.calculate(reference.reference_poll, calculation_opts)
			Map.put(reference, :reference_poll, Map.put(reference.reference_poll, :results, results))
		end)
		|> Enum.sort(&(&1.reference_poll.results.mean > &2.reference_poll.results.mean))
	end

	def inverse_for_poll(poll, calculation_opts) do
		from(d in Reference, where: d.reference_poll_id == ^poll.id, order_by: d.inserted_at)
		|> Repo.all
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		|> Enum.filter(fn(reference) ->
			approval_result = Result.calculate(reference.approval_poll, calculation_opts)
			approval_result.mean >= calculation_opts[:minimum_reference_approval_score]
		end)
		|> Enum.map(fn(reference) ->
			results = Result.calculate(reference.poll, calculation_opts)
			Map.put(reference, :poll, Map.put(reference.poll, :results, results))
		end)
		|> Enum.sort(&(&1.poll.results.mean > &2.poll.results.mean))
	end
end
