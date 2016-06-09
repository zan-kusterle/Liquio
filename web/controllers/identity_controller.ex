defmodule Democracy.IdentityController do
	use Democracy.Web, :controller

	alias Democracy.Identity

	plug :scrub_params, "identity" when action in [:create, :update]

	def index(conn, %{}) do
		identities = Repo.all(Identity)

		render(conn, "index.json", identities: identities)
	end

	def create(conn, %{"identity" => params}) do
		Repo.transaction fn ->
			trust_metric_poll = Repo.insert!(Democracy.Poll.new(%{
				:title => "is_human",
				:choices => ["true"],
				:topics => nil,
				:is_direct => true
			}))
			case Repo.insert(Identity.new(params, trust_metric_poll)) do
				{:ok, identity} ->
					conn
					|> put_status(:created)
					|> put_resp_header("location", identity_path(conn, :show, identity))
					|> render("show.json", identity: Map.put(identity, :insecure_token, identity.token))
				{:error, changeset} ->
					conn
					|> put_status(:unprocessable_entity)
					|> render(Democracy.ChangesetView, "error.json", changeset: changeset)
			end
		end
	end

	def show(conn, %{"id" => username}) do
		identity = Repo.get_by!(Identity, username: username)
		render(conn, "show.json", identity: identity)
	end
end
