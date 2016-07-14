defmodule Democracy.Plugs.ValidateFloat do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, func, constant, message}) do
		x = conn.params[assign_atom]
		is_valid = case func do
			">" ->
				x > constant
			">=" ->
				x >= constant
		end

		if not is_valid do
			conn
            |> Phoenix.Controller.put_flash(:error, message)
            |> Democracy.Plugs.RedirectBack.redirect_back
            |> halt
        else
        	conn
		end
	end
end