defmodule Liquio.HtmlExploreController do
	use Liquio.Web, :controller
	alias Liquio.Helpers.PollHelper

	def index(conn, %{"sort" => sort}) do
		polls = Poll |> Poll.sorted_for_keyword(sort) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))
		conn
		|> render("index.html",
			heading: "ALL POLLS",
			url: "/explore",
			sort: sort,
			polls: polls,
			identities: [])
	end

	def search(conn, %{"query" => query}) do
		polls = Poll |> Poll.search(query) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))
		conn
		|> render("index.html",
			heading: "RESULTS",
			query: query,
			polls: polls,
			identities: Identity |> Identity.search(query) |> Repo.all)
	end
end