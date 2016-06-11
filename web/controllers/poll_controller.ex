defmodule Democracy.PollController do
	use Democracy.Web, :controller

	alias Democracy.Poll
	alias Democracy.Vote
	alias Democracy.Results

	plug :scrub_params, "poll" when action in [:create]

	def create(conn, %{"poll" => params}) do
		changeset = Poll.changeset(%Poll{}, params)
		if changeset.valid? do
			poll = Repo.insert!(changeset)
			conn
			|> put_status(:created)
			|> put_resp_header("location", poll_path(conn, :show, poll))
			|> render("show.json", poll: poll)
		else
			conn
			|> put_status(:unprocessable_entity)
			|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
		end
	end

	def show(conn, %{"id" => id}) do
		poll = Repo.get(Poll, id)
		if poll do
			conn
			|> render("show.json", poll: poll)
		else
			conn
			|> put_status(:not_found)
			|> render(Democracy.ErrorView, "error.json", message: "Poll does not exist")
		end
	end

	def results(conn, %{"poll_id" => id}) do
		poll = Repo.get!(Poll, id)
		results = Results.get(poll)
		conn
		|> render("results.json", results: results)
	end
end
