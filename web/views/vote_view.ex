defmodule Democracy.VoteView do
	use Democracy.Web, :view

	def render("index.json", %{votes: votes}) do
		%{data: render_many(votes, Democracy.VoteView, "vote.json")}
	end

	def render("show.json", %{vote: vote}) do
		%{data: render_one(vote, Democracy.VoteView, "vote.json")}
	end

	def render("vote.json", %{vote: vote}) do
		%{
			id: vote.id,
			identity: %{id: vote.identity_id},
			poll: %{id: vote.poll_id},
			score: vote.data.score
		}
	end
end
