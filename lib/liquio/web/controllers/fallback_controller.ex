defmodule Liquio.Web.FallbackController do  
	use Liquio.Web, :controller

	def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
		conn
		|> put_status(:unprocessable_entity)
		|> render(Liquio.Web.ChangesetView, "error.json", changeset: changeset)
	end
end  