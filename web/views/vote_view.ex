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
			identity_id: vote.identity_id,
			poll_id: vote.poll_id,
			score_by_choices: vote.data.score_by_choices
		}
	end
end
