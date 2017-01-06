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
			title: poll.title
		}

		v = if Map.has_key?(poll, :topics) do
			Map.put(v, :topics, poll.topics |> Enum.map(fn(topic) ->
				topic.path
			end))
		else
			v
		end

		v = if Map.has_key?(poll, :results) do
			Map.put(v, :results, poll.results)
		else
			v
		end

		v = if Map.has_key?(poll, :embed) do
			Map.put(v, :html, poll.embed)
		else
			v
		end

		v = if Map.has_key?(poll, :contributions) do
			Map.put(v, :contributions, poll.contributions |> Enum.map(fn(contribution) ->
				%{
					:identity => Liquio.IdentityView.render("identity.json", identity: contribution.identity),
					:choice => contribution.choice,
					:voting_power => contribution.voting_power
				}	
			end))
		else
			v
		end

		v = if Map.has_key?(poll, :references) do
			Map.put(v, :references, poll.references |> Enum.map(fn(reference) ->
				%{:poll => render("poll.json", poll: reference.reference_poll)}
			end))
		else
			v
		end
		
		v
	end

	def render("results.json", %{results: results}) do
		results
	end
end
