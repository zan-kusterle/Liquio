defmodule Liquio.TopicController do
	use Liquio.Web, :controller
	alias Liquio.Helpers.PollHelper

	def show(conn, %{"path" => path_text}) do
		sort = "top"
		path = String.split(String.downcase(path_text), ">") |> Enum.map(& String.trim(&1)) |> Enum.filter(& String.length(&1) > 0)
		calculation_opts = get_calculation_opts_from_conn(conn)
		polls = Poll |> Poll.by_default_topic(path) |> Poll.sorted_for_keyword(sort) |> Repo.all
		|> Enum.map(& &1 |> PollHelper.prepare(calculation_opts, nil) |> Map.drop([:contributions]))

		conn
		|> render(Liquio.PollView, "index.json", polls: polls)
	end
end
