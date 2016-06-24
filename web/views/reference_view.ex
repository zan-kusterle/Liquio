defmodule Democracy.ReferenceView do
	use Democracy.Web, :view

	def render("index.json", %{references: references}) do
		%{data: render_many(references, Democracy.ReferenceView, "reference.json")}
	end

	def render("show.json", %{reference: reference}) do
		%{data: render_one(reference, Democracy.ReferenceView, "reference.json")}
	end

	def render("reference.json", %{reference: reference}) do
		%{
			id: reference.id,
			poll: Democracy.PollView.render("poll.json", poll: reference.poll),
			reference_poll: Democracy.PollView.render("poll.json", poll: reference.reference_poll),
			pole: reference.pole
		}
	end
end
