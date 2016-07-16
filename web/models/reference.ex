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

	def for_poll(poll, calculate_opts) do
		from(d in Reference, where: d.poll_id == ^poll.id, order_by: d.inserted_at)
		|> Repo.all
		|> Repo.preload([:approval_poll, :reference_poll, :poll])
		|> Enum.filter(fn(reference) ->
			approval_result = Result.calculate(reference.approval_poll, calculate_opts)
			is_approved = approval_result.mean >= 0.5
			is_approved
		end)
		|> Enum.map(fn(reference) ->
			results = Result.calculate(reference.reference_poll, calculate_opts)
			Map.put(reference, :reference_poll, Map.put(reference.reference_poll, :results, results))
		end)
		|> Enum.sort(&(&1.reference_poll.results.mean > &2.reference_poll.results.mean))
	end
end
