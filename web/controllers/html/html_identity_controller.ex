defmodule Democracy.HtmlIdentityController do
	use Democracy.Web, :controller

	def new(conn, _params) do
		conn
		|> render("new.html")
	end

	def create(conn, params) do
		token = Identity.generate_token()
		result = Identity.create(Identity.changeset(%Identity{token: token}, params))

		result |> handle_errors(conn, fn identity ->
			conn
			|> Guardian.Plug.sign_in(identity)
			|> put_flash(:info, "Hello, #{identity.name}")
			|> render("credentials.html", identity: identity, token: token)
		end)
	end

	with_params(%{
		:identity => {Plugs.ItemParam, [schema: Identity, name: "id"]}
	},
	def show(conn, %{:identity => identity}) do
		current_identity = Guardian.Plug.current_resource(conn)
		is_me = current_identity != nil and identity.id == current_identity.id
		own_is_human_vote =
			if current_identity != nil do
				vote = Repo.get_by(Vote, identity_id: current_identity.id, poll_id: identity.trust_metric_poll_id, is_last: true)
				if vote != nil and vote.data == nil do vote = nil end
				vote
			else
				nil
			end

		num_votes = Repo.one(
			from(v in Vote,
			where: v.identity_id == ^identity.id
				and v.is_last == true
				and not is_nil(v.data),
			select: count(v.id))
		)

		delegation = if current_identity != nil and not is_me do
			delegation = Repo.get_by(Delegation, %{from_identity_id: current_identity.id, to_identity_id: identity.id, is_last: true})
			if delegation != nil and delegation.data != nil do
				delegation
			else
				nil
			end
		else
			nil
		end

		delegations_from = from(d in Delegation, where: d.from_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])

		delegations_to = from(d in Delegation, where: d.to_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: identity.name,
			identity: identity,
			is_me: is_me,
			own_is_human_vote: own_is_human_vote,
			num_votes: num_votes,
			is_trusted: true,
			delegation: delegation,
			delegations_to: delegations_to,
			delegations_from: delegations_from)
	end)

	with_params(%{
		:user => {Plugs.CurrentUser, []},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url", maybe: true]},
		:vote_weight_halving_days => {Plugs.NumberParam, [name: "vote_weight_halving_days", maybe: true, whole: true]},
		:soft_quorum_t => {Plugs.NumberParam, [name: "soft_quorum_t", maybe: true]},
		:minimum_reference_approval_score => {Plugs.NumberParam, [name: "minimum_reference_approval_score", maybe: true]},
	},
	def update(conn, params = %{:user => user}) do
		IO.inspect params
		result = Identity.update_preferences(Identity.update_changeset(user, params
			|> Map.take([:trust_metric_url, :vote_weight_halving_days, :soft_quorum_t, :minimum_reference_approval_score])))

		result |> handle_errors(conn, fn user ->
			conn
			|> put_flash(:info, "Your preferences have been updated")
			|> redirect(to: default_redirect conn)
		end)
	end)
end
