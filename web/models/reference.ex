defmodule Democracy.Reference do
	use Democracy.Web, :model

	alias Democracy.Repo
	alias Democracy.Reference
	alias Democracy.Poll

	schema "references" do
		belongs_to :poll, Poll
		belongs_to :reference_poll, Poll
		belongs_to :approval_poll, Poll
		field :pole, :string

		timestamps
	end

	def get(poll, reference_poll, pole) do
		reference = Repo.get_by(Reference, poll_id: poll.id, reference_poll_id: reference_poll.id, pole: pole)
		if reference == nil do
			approval_poll = Repo.insert!(%Poll{
				:kind => "is_reference",
				:title => nil,
				:topics => nil
			})
			reference = Repo.insert!(%Reference{
				:poll => poll,
				:reference_poll => reference_poll,
				:approval_poll => approval_poll,
				:pole => pole
			})
		end
		reference
	end
end
