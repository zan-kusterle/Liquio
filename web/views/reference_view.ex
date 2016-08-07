defmodule Liquio.ReferenceView do
	use Liquio.Web, :view

	def render("index.json", %{references: references}) do
		%{data: render_many(references, Liquio.ReferenceView, "reference.json")}
	end

	def render("show.json", %{reference: reference}) do
		%{data: render_one(reference, Liquio.ReferenceView, "reference.json")}
	end

	def render("reference.json", %{reference: reference}) do
		v = %{
			id: reference.id,
			poll: Liquio.PollView.render("poll.json", poll: reference.poll),
			reference_poll: Liquio.PollView.render("poll.json", poll: reference.reference_poll),
			approval_poll: Liquio.PollView.render("poll.json", poll: reference.approval_poll),
			for_choice: reference.for_choice
		}
	end
end
