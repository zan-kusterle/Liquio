defmodule Liquio.TopicController do
	use Liquio.Web, :controller
	alias Liquio.Helpers.PollHelper

	def show(conn, %{"path" => path_text}) do
		sort = "top"
		path = String.split(String.downcase(path_text), ">") |> Enum.map(& String.trim(&1)) |> Enum.filter(& String.length(&1) > 0)
		polls = Poll |> Poll.by_default_topic(path) |> Poll.sorted_for_keyword(sort) |> Repo.all
		|> Enum.map(& PollHelper.prepare(&1, nil, nil, from_default_cache: true))

		conn
		|> render(Liquio.PollView, "index.json", polls: polls)
	end
end
