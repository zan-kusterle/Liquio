defmodule Liquio.HtmlIdentityController do
	use Liquio.Web, :controller

	def new(conn, _params) do
		conn
		|> render("new.html")
	end

	def create(conn, params) do
		password = Identity.generate_password()
		result = Identity.create(Identity.changeset(%Identity{
			password_hash: Comeonin.Bcrypt.hashpwsalt(password)
		}, params))

		result |> handle_errors(conn, fn identity ->
			conn
			|> Guardian.Plug.sign_in(identity)
			|> put_flash(:info, "Hello, #{identity.name}")
			|> render("credentials.html", identity: identity, password: password)
		end)
	end

	with_params(%{
		:identity => {Plugs.ItemParam, [schema: Identity, name: "id"]}
	},
	def show(conn, %{:identity => identity}) do
		calculation_opts = get_calculation_opts_from_conn(conn)

		current_identity = Guardian.Plug.current_resource(conn)
		is_me = current_identity != nil and identity.id == current_identity.id
		is_in_trust_metric = Enum.member?(calculation_opts[:trust_metric_ids], to_string(identity.id))
		own_is_human_vote =
			if current_identity != nil do
				vote = Repo.get_by(Vote, identity_id: current_identity.id, poll_id: identity.trust_metric_poll_id, is_last: true)
				if vote == nil or vote.data == nil do
					nil
				else
					vote
				end
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

		num_delegations_from = Repo.one(
			from(d in Delegation,
			where: d.from_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data),
			select: count(d.id))
		)
		num_delegations_to = Repo.one(
			from(d in Delegation,
			where: d.to_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data),
			select: count(d.id))
		)
		
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("show.html",
			title: identity.name,
			identity: identity,
			is_me: is_me,
			default_trust_metric_url: Liquio.TrustMetric.default_trust_metric_url(),
			calculation_opts: calculation_opts,
			is_in_trust_metric: is_in_trust_metric,
			own_is_human_vote: own_is_human_vote,
			num_votes: num_votes,
			is_trusted: true,
			delegation: delegation,
			num_delegations_to: num_delegations_to,
			num_delegations_from: num_delegations_from)
	end)

	with_params(%{
		:identity => {Plugs.ItemParam, [schema: Identity, name: "html_identity_id"]}
	},
	def delegations_from(conn, %{:identity => identity}) do
		query = from(d in Delegation, where: d.from_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data))
		delegations_from = query
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		|> Enum.sort(& &1.data.weight > &2.data.weight)

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("delegations.html",
			title: "Delegations from #{identity.name}",
			identity: identity,
			direction: "from",
			delegations: delegations_from
		)
	end)

	with_params(%{
		:identity => {Plugs.ItemParam, [schema: Identity, name: "html_identity_id"]}
	},
	def delegations_to(conn, %{:identity => identity}) do
		query = from(d in Delegation, where: d.to_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data))
		delegations_to = query
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		|> Enum.sort(& &1.data.weight > &2.data.weight)

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("delegations.html",
			title: "Delegations to #{identity.name}",
			identity: identity,
			direction: "to",
			delegations: delegations_to
		)
	end)

	with_params(%{
		:identity => {Plugs.ItemParam, [schema: Identity, name: "html_identity_id"]}
	},
	def votes(conn, %{:identity => identity}) do
		calculation_opts = get_calculation_opts_from_conn(conn)

		query = from(v in Vote, where: v.identity_id == ^identity.id and v.is_last == true and not is_nil(v.data))
		votes = query
		|> Repo.all
		|> Repo.preload([:poll])

		voted_polls = votes |> Enum.map(fn(vote) ->
			vote.poll
			|> Map.put(:score, vote.data.score)
		end)
		polls = voted_polls
		|> Enum.flat_map(& expand_poll(&1, calculation_opts))
		|> Enum.reduce(%{}, fn(poll, acc) ->
			existing_poll = Map.get(acc, poll.id, %{})
			merged_poll = Map.merge(existing_poll, poll, fn _k, v1, v2 ->
				cond do
					v1 == nil and v2 == nil ->
						nil
					v1 == nil ->
						v2
					v2 == nil ->
						v1
					true ->
						v1
				end
			end)
			acc |> Map.put(poll.id, merged_poll)
		end)
		|> Map.values
		{is_human_polls, other_polls} = Enum.partition(polls, &(&1.kind == "is_human"))

		groups = if Enum.empty?(other_polls) do
			[]
		else
			polls_by_ids = for poll <- other_polls, into: %{} do
				{poll.id, poll}
			end
			root_ids = polls_by_ids |> Map.keys |> Enum.filter(fn(id) ->
				num_references = polls_by_ids |> Map.values |> Enum.filter(fn poll ->
					Enum.find(poll.references, & &1.reference_poll_id == id) != nil
				end) |> Enum.count
				num_references == 0
			end)
			root_ids = if Enum.empty?(root_ids) do
				[polls_by_ids |> Map.keys |> Enum.at(0)]
			else
				root_ids
			end
			root_ids |> Enum.map(fn id ->
				traverse_polls(polls_by_ids, id, MapSet.new, 0, nil)
			end)
		end

		is_human_votes = is_human_polls |> Enum.map(fn poll ->
			identity = Repo.get_by!(Identity, trust_metric_poll_id: poll.id)
			%{
				:identity => identity,
				:poll => poll
			}
		end)
		
		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("votes.html",
			title: "Votes of #{identity.name}",
			identity: identity,
			groups: groups,
			is_human_votes: is_human_votes
		)
	end)

	def traverse_polls(polls_by_ids, id, visited, level, reference) do
		visited = MapSet.put(visited, id)

		current = polls_by_ids[id] |> Map.put(:level, level) |> Map.put(:reference, reference)
		sub = Enum.flat_map(polls_by_ids[id].references, fn(reference = %{:reference_poll_id => reference_poll_id}) ->
			if Map.has_key?(polls_by_ids, reference_poll_id) do
				traverse_polls(polls_by_ids, reference_poll_id, visited, level + 1, reference)
			else
				[]
			end
		end)

		[current] ++ sub
	end

	with_params(%{
		:user => {Plugs.CurrentUser, [require: true]},
		:trust_metric_url => {Plugs.StringParam, [name: "trust_metric_url", maybe: true]},
		:vote_weight_halving_days => {Plugs.NumberParam, [name: "vote_weight_halving_days", maybe: true, whole: true]},
		:soft_quorum_t => {Plugs.NumberParam, [name: "soft_quorum_t", maybe: true]},
		:minimum_reference_approval_score => {Plugs.NumberParam, [name: "minimum_reference_approval_score", maybe: true]},
		:minimum_voting_power => {Plugs.NumberParam, [name: "minimum_voting_power", maybe: true]},
	},
	def update(conn, params = %{:user => user}) do
		params = if params.vote_weight_halving_days >= 1000 do
			Map.put(params, :vote_weight_halving_days, nil)
		else
			params
		end
		
		result = Identity.update_preferences(Identity.update_changeset(user, params
			|> Map.take([:trust_metric_url, :vote_weight_halving_days, :soft_quorum_t, :minimum_reference_approval_score, :minimum_voting_power])))

		result |> handle_errors(conn, fn _user ->
			conn
			|> put_flash(:info, "Using your new preferences when calculating results")
			|> redirect(to: default_redirect conn)
		end)
	end)

	defp prepare_poll(poll, data) do
		Map.merge(Map.merge(%{
			:references => [],
			:score => nil,
			:approval_score => nil
		}, poll), data)
	end

	defp expand_poll(poll, calculation_opts) do
		case poll.kind do
			"custom" ->
				references = poll
				|> Reference.for_poll(calculation_opts)
				|> Repo.preload([:poll, :reference_poll])
				[prepare_poll(poll, %{:score => poll.score, :references => references})]
			"is_reference" ->
				reference = Reference
				|> Repo.get_by!(approval_poll_id: poll.id)
				|> Repo.preload([:poll, :reference_poll])

				references = reference.poll
				|> Reference.for_poll(calculation_opts)
				|> Repo.preload([:poll, :reference_poll])
				reference_poll_references = reference.reference_poll
				|> Reference.for_poll(calculation_opts)
				|> Repo.preload([:poll, :reference_poll])

				references = if Enum.find(references, &(&1.reference_poll_id == reference.reference_poll.id and &1.for_choice == reference.for_choice)) == nil do
					references ++ [%{:reference_poll_id => reference.reference_poll.id, :for_choice => reference.for_choice, :poll => reference.poll}]
				else
					references
				end

				[
					prepare_poll(reference.poll, %{:references => references}),
					prepare_poll(reference.reference_poll, %{:references => reference_poll_references, :approval_score => poll.score})
				]
			_ ->
				[prepare_poll(poll, %{})]
		end
	end
end
