defmodule Liquio.HtmlVoteController do
	use Liquio.Web, :controller

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:node => {Plugs.NodeParam, [name: "html_poll_id"]},
		:choice => {Plugs.StringParam, [name: "choice", maybe: true]}
	},
	def create(conn, %{:user => user, :node => node, :choice => choice}) do
		reference_node = if Map.has_key?(conn.params, "reference_key") do
			Node.from_key(conn.params["reference_key"])
		else
			nil
		end
		node = Node.for_reference_key(node, reference_node && reference_node.key)

		calculation_opts = get_calculation_opts_from_conn(conn)

		{level, message} =
			if choice != nil and choice != "null" do
				case parse_choice(choice, node.choice_type) do
					{:ok, choice} ->
						Vote.set(node, user, choice)
						if MapSet.member?(calculation_opts.trust_metric_ids, to_string(user.id)) do
							{:info, "Your vote is now live. Share the poll with other people."}
						else
							{:error, "Your vote is now live, but because you're not in trust metric it will not be counted. Get others to trust your identity by sharing it's URL to get into trust metric or change it in preferences."}
						end
					{:error, message} ->
						{:error, message}
				end
			else
				Vote.delete(node, user)
				{:info, "You no longer have a vote in this poll."}
			end

		conn
		|> put_flash(level, message)
		|> redirect(to: Liquio.Controllers.Helpers.default_redirect(conn))
	end)

	def parse_choice(choice, choice_type) do
		case choice_type do
			"probability" ->
				case Float.parse(choice) do
					{x, ""} ->
						if x >= 0 and x <= 1 do
							{:ok, %{:main => x}}
						else
							{:error, "Choice must be between 0 (0%) and 1 (100%)."}
						end
					_ ->
						{:error, "Choice must be a number."}
				end
			"quantity" ->
				case Float.parse(choice) do
					{x, ""} ->
						{:ok, %{:main => x}}
					_ ->
						{:error, "Choice must be a number."}
				end
			"time_quantity" ->
				choices = choice |> String.split("\n") |> Enum.map(fn(line) ->
					line = String.replace(line, "\r", "")
					parts = String.split(line, ":")
					if Enum.count(parts) == 2 do
						date_string = Enum.at(parts, 0) |> String.trim
						value_string = Enum.at(parts, 1) |> String.trim

						value = case Float.parse(value_string) do
							{x, ""} ->
								x
							_ ->
								nil
						end

						datetime = case Timex.parse(date_string, "{YYYY}") do
							{:ok, x} ->
								x
							_ ->
								nil
						end

						if value != nil and datetime != nil do
							{datetime |> Timex.format!("{YYYY}"), value}
						else
							nil
						end
					else
						nil
					end
				end)

				if Enum.any?(choices, & &1 == nil) do
					{:error, "Your choice was not in the correct format."}
				else
					{:ok, Enum.into(choices, %{})}
				end
		end
	end
end