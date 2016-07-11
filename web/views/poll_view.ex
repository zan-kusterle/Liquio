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
			choice_type: poll.choice_type,
			title: poll.title,
			topics: poll.topics,
		}
		if Map.has_key?(poll, :results) do
			v = Map.put(v, :results, poll.results)
		end
		if Map.has_key?(poll, :contributions) do
			v = Map.put(v, :contributions, poll.contributions)
		end
		v
	end

	def render("results.json", %{results: results}) do
		results
	end
end
