defmodule Democracy.Plugs.Params do
	import Plug.Conn

	def init(default), do: default

	def call(conn, list) do
		results = Enum.map(list, fn({handle, name, opts}) ->
			result = case handle do
				:item ->
					handle_item(conn, opts)
				:identity ->
					identity = Guardian.Plug.current_resource(conn)
					if identity == nil do
						{:error, :unauthorized, "No current user"}
					else
						{:ok, identity}
					end
				:number ->
					{:ok, 2.0}
				:topics ->
					{:ok, ["science", "nature"]}
			end
			case result do
				{:ok, value} ->
					{:ok, name, [value: value]}
				{:error, status, message} ->
					{:error, name, [status: status, message: message]}
			end
		end)
		errors = Enum.filter(results, fn({status, name, data}) -> status == :error end)
		if Enum.count(errors) > 0 do
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Invalid query parameter")
			|> halt
		else
			params = for {:ok, name, data} <- results, into: %{} do
				{name, data[:value]}
			end
			%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(params)}
		end
	end

	def handle_item(conn, opts) do
		item = Democracy.Repo.get(opts[:schema], conn.params[opts[:name]])
		if item != nil do
			{:ok, item}
		else
			{:error, :not_found, opts[:message] || "Not found"}
		end
	end
end