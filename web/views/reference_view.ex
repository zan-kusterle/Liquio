defmodule Democracy.ReferenceView do
	use Democracy.Web, :view

	def render("index.json", %{references: references}) do
		%{data: render_many(references, Democracy.ReferenceView, "reference.json")}
	end

	def render("show.json", %{reference: reference}) do
		%{data: render_one(reference, Democracy.ReferenceView, "reference.json")}
	end

	def render("reference.json", %{reference: reference}) do
		v = %{
			id: reference.id,
			poll: Democracy.PollView.render("poll.json", poll: reference.poll),
			reference_poll: Democracy.PollView.render("poll.json", poll: reference.reference_poll),
			approval_poll_id: reference.approval_poll_id,
			pole: reference.pole,
		}
		if Map.has_key?(reference, :is_approved) do
			v = Map.put(v, :is_approved, reference.is_approved)
		end
	end
end
