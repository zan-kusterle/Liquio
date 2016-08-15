defmodule Liquio.PollView do
	use Liquio.Web, :view

	def render("index.json", %{polls: polls}) do
		%{data: render_many(polls, Liquio.PollView, "poll.json")}
	end

	def render("show.json", %{poll: poll}) do
		%{data: render_one(poll, Liquio.PollView, "poll.json")}
	end

	def render("poll.json", %{poll: poll}) do
		v = %{
			id: poll.id,
			kind: poll.kind,
			choice_type: poll.choice_type,
			title: poll.title,
			topics: poll.topics,
		}
		v = if Map.has_key?(poll, :results) do
			Map.put(v, :results, poll.results)
		else
			v
		end
		v = if Map.has_key?(poll, :contributions) do
			Map.put(v, :contributions, poll.contributions)
		else
			v
		end
		v
	end

	def render("results.json", %{results: results}) do
		results
	end
end
