defmodule Liquio.VoteView do
	use Liquio.Web, :view

	def render("index.json", %{votes: votes}) do
		%{data: render_many(votes, Liquio.VoteView, "vote.json")}
	end

	def render("show.json", %{vote: vote}) do
		%{data: render_one(vote, Liquio.VoteView, "vote.json")}
	end

	def render("vote.json", %{vote: vote}) do
		%{
			id: vote.id,
			identity: %{id: vote.identity_id},
			key: vote.key,
			title: vote.title,
			choice: if vote.data do vote.data.choice else nil end
		}
	end
end
