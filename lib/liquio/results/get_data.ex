defmodule Liquio.GetData do
  def get_using_cache(whitelist_url, trust_usernames) do
    get(whitelist_url, trust_usernames)
  end

  def get(whitelist_url, trust_usernames) do
    url = "#{Application.get_env(:liquio, :messages_url)}/"

    url =
      if whitelist_url do
        "#{url}?whitelist_url=#{whitelist_url}&"
      else
        url
      end

    url =
      if trust_usernames do
        "#{url}#{
          if whitelist_url do
            "&"
          else
            "?"
          end
        }usernames=#{Enum.join(trust_usernames, ",")}"
      else
        url
      end

    response = HTTPotion.get(url)

    if HTTPotion.Response.success?(response) do
      messages = Poison.decode!(response.body)["data"]

      messages_by_name = Enum.group_by(messages, & &1["data"]["name"])

      data = %{
        :delegations => get_delegations(Map.get(messages_by_name, "trust", [])),
        :votes => get_votes(Map.get(messages_by_name, "vote", [])),
        :reference_votes => get_reference_votes(Map.get(messages_by_name, "reference_vote", []))
      }

      {:ok, data}
    else
      {:error, "Unable to fetch data"}
    end
  end

  defp get_delegations(messages) do
    Enum.map(messages, fn message ->
      data = message["data"]

      %{
        :username => message["username"],
        :to_username => data["username"],
        :weight => data["ratio"]
      }
    end)
    |> Enum.filter(&(&1.weight != nil))
  end

  defp get_votes(messages) do
    messages
    |> filter_messages_with_formats(%{
      "title" => %{ type: "string", min_length: 3 },
      "unit" => %{ type: "string", min_length: 2 },
      "choice" => %{ type: "number" },
      "key" => %{ type: "list", in: [
        ["vote", "title", "unit"],
        ["vote", "title", "unit", "comments"],
        ["vote", "title", "anchor", "unit"],
        ["vote", "title", "anchor", "unit", "comments"],
      ]}
    })
    |> Enum.map(fn message ->
      data = message["data"]

      %{
        :username => message["username"],
        :title => data["title"],
        :anchor => Map.get(data, "anchor"),
        :unit => data["unit"],
        :comments => Map.get(data, "comments", []),
        :choice => data["choice"],
        :at_date => Map.get(data, "at_date", message["datetime"])
      }
    end)
    |> Enum.filter(&(&1.choice != nil))
  end

  defp get_reference_votes(messages) do
    messages
    |> Enum.filter(fn message ->
      data = message["data"]

      String.length(data["title"]) >= 3 and String.length(data["reference_title"]) >= 3 and
        (is_integer(data["relevance"]) or is_float(data["relevance"])) and data["relevance"] >= 0 and
        data["relevance"] <= 1 and data["key"] == ["reference_vote", "title", "reference_title"]
    end)
    |> Enum.map(fn message ->
      data = message["data"]

      %{
        :username => message["username"],
        :title => data["title"],
        :anchor => Map.get(data, "anchor"),
        :unit => data["unit"],
        :comments => Map.get(data, "comments", []),
        :reference_title => data["reference_title"],
        :reference_anchor => Map.get(data, "reference_anchor"),
        :reference_unit => data["reference_unit"],
        :reference_comments => Map.get(data, "reference_comments", []),
        :choice => data["relevance"]
      }
    end)
    |> Enum.filter(&(&1.choice != nil))
  end

  defp filter_messages_with_formats(messages, formats_by_fields) do
    Enum.filter(messages, fn message ->
      data = message["data"]

      Enum.map(formats_by_fields, fn { key, options } ->
        value = Map.get(data, key)
        case options.type do
          "string" ->
            is_bitstring(value) and String.length(value) > Map.get(options, :min_length, 0)
          "number" ->
            is_float(value)
          "list" ->
            is_list(value) and Enum.all?(value, & Enum.member?(options.in, &1))
        end        
      end)
    end)
  end
end
