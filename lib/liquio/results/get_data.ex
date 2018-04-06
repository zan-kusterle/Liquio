defmodule Liquio.GetData do
    def get(trust_metric_url, trust_usernames) do
        url = "http://localhost:5000/?usernames=#{Enum.join(trust_usernames, ",")}"
        response = HTTPotion.get url
        if HTTPotion.Response.success?(response) do
            messages = Poison.decode!(response.body)

            messages_by_name = Enum.group_by(messages, & &1["data"]["name"])

            data = %{
                :identifications => get_identifications(Map.get(messages_by_name, "identification", [])),
                :delegations => get_delegations(Map.get(messages_by_name, "delegation", [])),
                :votes => get_votes(Map.get(messages_by_name, "vote", [])),
                :reference_votes => get_reference_votes(Map.get(messages_by_name, "reference_vote", [])),
            }

            {:ok, data}
        else
            {:error, "Unable to fetch data"}
        end
    end

    defp get_identifications(messages) do
        Enum.map(messages, fn(message) ->
            data = message["data"]
            %{
                :username => message["username"],
                :type => data["type"],
                :value => data["value"]
            }
        end)
    end

    defp get_delegations(messages) do
        Enum.map(messages, fn(message) ->
            data = message["data"]
            %{
                :username => message["username"],
                :to_username => data["to_username"]
            }
        end)
    end

    defp get_votes(messages) do
        Enum.map(messages, fn(message) ->
            data = message["data"]
            %{
                :username => message["username"],
                :title => data["title"],
                :unit => data["unit"],
                :choice => data["choice"],
                :at_date => Map.get(data, "at_date", message["datetime"])
            }
        end)
    end

    defp get_reference_votes(messages) do
        Enum.map(messages, fn(message) ->
            %{}
        end)
    end
end