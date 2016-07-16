defmodule Democracy.Controllers.Helpers do
	def default_redirect(conn) do
		if Map.get(conn.params, "redirect") do
			conn.params["redirect"]
		else
			case List.keyfind(conn.req_headers, "referer", 0) do
				{"referer", referer} ->
					url = URI.parse(referer)
					url.path
				nil ->
					"/"
			end
		end
	end

	def handle_errors({:error, changeset}, conn, _func) do
		conn
		|> Phoenix.Controller.put_flash(:error, "Couldn't create identity")
		|> Phoenix.Controller.redirect to: "/"
	end

	def handle_errors({:ok, item}, _conn, func) do
		func.(item)
	end
end