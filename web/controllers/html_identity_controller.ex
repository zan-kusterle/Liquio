defmodule Liquio.HtmlIdentityController do
	use Liquio.Web, :controller

	def create(conn, params) do
		email = Token.get_email(params["token"])
		if email == nil do
			conn
			|> put_flash(:info, "Error logging in, please try again")
			|> redirect(to: html_login_path(conn, :index))
		else
			result = Identity.create(Identity.changeset(%Identity{email: email}, params))

			result |> handle_errors(conn, fn identity ->
				Token.use(params["token"])
				conn
				|> Guardian.Plug.sign_in(identity)
				|> put_flash(:info, "Hello, #{identity.name}")
				|> redirect(to: html_identity_path(conn, :show, identity.id))
			end)
		end
	end

	with_params(%{
		:identity => {Plugs.ItemParam, [schema: Identity, name: "id", column: :username]}
	},
	def show(conn, %{:identity => identity}) do
		calculation_opts = get_calculation_opts_from_conn(conn)

		current_identity = Guardian.Plug.current_resource(conn)

		is_in_trust_metric = Enum.member?(calculation_opts[:trust_metric_ids], to_string(identity.id))
		own_is_human_vote = nil
		
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: identity.name,
			identity: identity,
			default_trust_metric_url: Liquio.TrustMetric.default_trust_metric_url(),
			calculation_opts: calculation_opts)
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url", maybe: true]},
		:vote_weight_halving_days => {Plugs.NumberParam, [name: "vote_weight_halving_days", maybe: true, whole: true]},
		:reference_minimum_turnout => {Plugs.NumberParam, [name: "reference_minimum_turnout", maybe: true]},
		:reference_minimum_agree => {Plugs.NumberParam, [name: "reference_minimum_agree", maybe: true]},
		:minimum_turnout => {Plugs.NumberParam, [name: "minimum_voting_power", maybe: true]},
	},
	def update(conn, params = %{:user => user}) do
		params = if params.vote_weight_halving_days >= 1000 do
			Map.put(params, :vote_weight_halving_days, nil)
		else
			params
		end
		
		result = Identity.update_preferences(Identity.update_changeset(user, params
			|> Map.take([:trust_metric_url, :minimum_turnout, :vote_weight_halving_days, :reference_minimum_turnout, :reference_minimum_agree])))

		result |> handle_errors(conn, fn _user ->
			conn
			|> put_flash(:info, "Using your new preferences when calculating results.")
			|> redirect(to: default_redirect conn)
		end)
	end)
end
