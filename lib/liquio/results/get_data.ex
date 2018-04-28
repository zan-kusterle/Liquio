defmodule Liquio.GetData do
	def get_using_cache(whitelist_url, trust_usernames) do
		get(whitelist_url, trust_usernames)    
	end

	def get(whitelist_url, trust_usernames) do
		url = "#{Application.get_env(:liquio, :messages_url)}/"
		url = if whitelist_url do
			"#{url}?whitelist_url=#{whitelist_url}&"
		else
			url
		end
		url = if trust_usernames do
			"#{url}#{if whitelist_url do "&" else "?" end}usernames=#{Enum.join(trust_usernames, ",")}"
		else
			url
		end

		response = HTTPotion.get url
		if HTTPotion.Response.success?(response) do
			messages = Poison.decode!(response.body)["data"]

			messages_by_name = Enum.group_by(messages, & &1["data"]["name"])

			data = %{
				:delegations => get_delegations(Map.get(messages_by_name, "trust", [])),
				:votes => get_votes(Map.get(messages_by_name, "vote", [])),
				:reference_votes => get_reference_votes(Map.get(messages_by_name, "reference_vote", [])),
			}

			{:ok, data}
		else
			{:error, "Unable to fetch data"}
		end
	end

	defp get_delegations(messages) do
		Enum.map(messages, fn(message) ->
			data = message["data"]
			%{
				:username => message["username"],
				:to_username => data["username"],
				:weight => data["ratio"]
			}
		end)
		|> Enum.filter(& &1.weight != nil)
	end

	defp get_votes(messages) do
		messages
		|> Enum.filter(fn(message) ->
			data = message["data"]

			String.length(data["title"]) >= 3 and
			String.length(data["unit"]) >= 2 and
			(is_integer(data["choice"]) or is_float(data["choice"])) and
			data["key"] == ["vote", "title", "unit"]
		end)
		|> Enum.map(fn(message) ->
			data = message["data"]
			%{
				:username => message["username"],
				:title => data["title"],
				:unit => data["unit"],
				:choice => data["choice"],
				:at_date => Map.get(data, "at_date", message["datetime"])
			}
		end)
		|> Enum.filter(& &1.choice != nil)
	end

	defp get_reference_votes(messages) do
		messages
		|> Enum.filter(fn(message) ->
			data = message["data"]

			String.length(data["title"]) >= 3 and
			String.length(data["reference_title"]) >= 3 and
			is_float(data["relevance"]) and data["relevance"] >= 0 and data["relevance"] <= 1 and
			data["key"] == ["reference_vote", "title", "reference_title"]
		end)
		|> Enum.map(fn(message) ->
			data = message["data"]
			%{
				:username => message["username"],
				:title => data["title"],
				:reference_title => data["reference_title"],
				:choice => data["relevance"]
			}
		end)
		|> Enum.filter(& &1.choice != nil)
	end
end