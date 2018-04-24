defmodule Liquio.Web.SearchController do
	use Liquio.Web, :controller
	
	def show(conn, params = %{"query" => query}) do
		whitelist_url = Map.get(params, "whitelist_url")
		whitelist_usernames = params
		|> Map.get("whitelist_usernames", "")
		|> String.split(",")
		|> Enum.filter(& String.length(&1) > 0)
		
		results = case Liquio.GetData.get_using_cache(whitelist_url, whitelist_usernames) do
			{:ok, data} ->
				Liquio.Search.query(data, query)
			{:error, _message} ->
				[]
		end

		conn
		|> render("index.json", nodes: results)
	end
end
