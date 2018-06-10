defmodule LiquioWeb.NodeController do
  use LiquioWeb, :controller

  alias Liquio.Node

  def show(conn, params = %{"title" => title}) do
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

    node = Node.new(title)

    node =
      case Liquio.GetData.get_using_cache(whitelist_url, whitelist_usernames) do
        {:ok, data} ->
          Node.load(node, data, depth)

        {:error, _message} ->
          node
      end

    conn
    |> render("show.json", node: node)
  end
end
