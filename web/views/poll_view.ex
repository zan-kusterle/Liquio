defmodule Democracy.PollView do
	use Democracy.Web, :view

	def render("index.json", %{polls: polls}) do
		%{data: render_many(polls, Democracy.PollView, "poll.json")}
	end

	def render("show.json", %{poll: poll}) do
		%{data: render_one(poll, Democracy.PollView, "poll.json")}
	end

	def render("poll.json", %{poll: poll}) do
		v = %{
			id: poll.id,
			kind: poll.kind,
			title: poll.title,
			choices: poll.choices,
			topics: poll.topics,
			is_direct: poll.is_direct
		}
		v
	end

	def render("results.json", %{results: results}) do
		results
	end
end
