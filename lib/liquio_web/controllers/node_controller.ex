defmodule LiquioWeb.NodeController do
  use LiquioWeb, :controller

  alias Liquio.Node

  def index(conn, params = %{"title" => title}) do
    whitelist_url = Map.get(params, "whitelist_url")

    whitelist_usernames =
      params
      |> Map.get("whitelist_usernames", "")
      |> String.split(",")
      |> Enum.filter(&(String.length(&1) > 0))

    depth =
      if Map.has_key?(params, "depth") do
        case Integer.parse(params["depth"]) do
          {number, _} -> min(2, number)
          :error -> 1
        end
      else
        1
      end

      
      nodes =
      case Liquio.GetData.get_using_cache(whitelist_url, whitelist_usernames) do
        {:ok, data} ->
          Node.list_by_title(title, data, depth)
        {:error, _message} ->
          []
      end

    conn
    |> render("index.json", nodes: nodes)
  end
end
