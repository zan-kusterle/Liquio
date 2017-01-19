defmodule Liquio.Plugs.ChoiceParam do
	def handle(conn, value, _opts) do
		if value != nil and value != "null" do
			parse_choice(value, Map.get(conn.params, "choice_type"))
		else
			{:ok, nil}
		end
	end

	defp parse_choice(choice, choice_type) do
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