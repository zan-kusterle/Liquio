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
				Token.use( params["token"])
				conn
				|> Guardian.Plug.sign_in(identity)
				|> put_flash(:info, "Hello, #{identity.name}")
				|> redirect(to: html_identity_path(conn, :show, identity.id))
			end)
		end
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
		|> Enum.sort(& &1.data.weight > &2.data.weight)

		delegations_to = from(d in Delegation, where: d.to_identity_id == ^identity.id and d.is_last == true and not is_nil(d.data))
		|> Repo.all
		|> Repo.preload([:from_identity, :to_identity])
		|> Enum.sort(& &1.data.weight > &2.data.weight)

		identity = identity |> Repo.preload([:trust_metric_poll_votes])
		trusted_by_identities =  identity.trust_metric_poll_votes
		|> Repo.preload([:identity])
		|> Enum.filter(& &1.is_last and &1.data != nil and &1.data.choice["main"] == 1.0)
		|> Enum.map(& &1.identity)
		|> Enum.sort(& &1.username > &2.username)

		votes = from(v in Vote, where: v.identity_id == ^identity.id and v.is_last == true and not is_nil(v.data))
		|> Repo.all
		|> Repo.preload([:poll])

		voted_polls = votes |> Enum.map(fn(vote) ->
			vote.poll
			|> Map.put(:choice, vote.data.choice)
		end)
		polls = voted_polls
		|> Enum.flat_map(& expand_poll(&1, calculation_opts))
		|> Enum.reduce(%{}, fn(poll, acc) ->
			existing_poll = Map.get(acc, poll.id, %{})
			merged_poll = Map.merge(existing_poll, poll, fn k, v1, v2 ->
				cond do
					v1 == nil and v2 == nil ->
						nil
					v1 == nil ->
						v2
					v2 == nil ->
						v1
					true ->
						case k do
							:references -> v1 ++ v2
							_ -> v1
						end
				end
			end)
			acc |> Map.put(poll.id, merged_poll)
		end)
		|> Map.values
		{is_human_polls, other_polls} = Enum.partition(polls, &(&1.kind == "is_human"))

		vote_groups = if Enum.empty?(other_polls) do
			[]
		else
			root_polls = other_polls |> Enum.filter(fn(poll) ->
				Enum.all?(other_polls, fn current_poll ->
					Enum.find(current_poll.references, & &1.reference_poll.id == poll.id) == nil
				end)
			end)
			root_polls = if Enum.empty?(root_polls) do
				[Enum.at(other_polls, 0)]
			else
				root_polls
			end

			polls_by_ids = for poll <- other_polls, into: %{} do
				{poll.id, poll}
			end
			root_polls |> Enum.map(fn poll ->
				traverse_polls(polls_by_ids, poll.id, MapSet.new, 0, nil)
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
		|> render("show.html",
			title: identity.name,
			identity: identity,
			is_me: is_me,
			default_trust_metric_url: Liquio.TrustMetric.default_trust_metric_url(),
			calculation_opts: calculation_opts,
			is_in_trust_metric: is_in_trust_metric,
			own_is_human_vote: own_is_human_vote,
			delegation: delegation,
			delegations_to: delegations_to,
			delegations_from: delegations_from,
			trusted_by_identities: trusted_by_identities,
			is_human_votes: is_human_votes,
			votes: votes,
			vote_groups: vote_groups)
	end)

	with_params(%{
		:identity => {Plugs.ItemParam, [schema: Identity, name: "html_identity_id"]}
	},
	def trusts_to(conn, %{:identity => identity}) do
		identity = identity |> Repo.preload([:trust_metric_poll_votes])
		identities =  identity.trust_metric_poll_votes
		|> Repo.preload([:identity])
		|> Enum.filter(& &1.is_last and &1.data != nil and &1.data.choice["main"] == 1.0)
		|> Enum.map(& &1.identity)
		|> Enum.sort(& &1.username > &2.username)

		conn
		|> put_resp_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
		|> render("identities.html",
			title: "People that trust #{identity.name}",
			identity: identity,
			identities: identities
		)
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
			|> Map.put(:choice, vote.data.choice)
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
		sub = Enum.flat_map(polls_by_ids[id].references, fn(reference = %{:reference_poll => %{:id => reference_poll_id}}) ->
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
		:approval_turnout_importance => {Plugs.NumberParam, [name: "soft_quorum_t", maybe: true]},
		:approval_minimum_score => {Plugs.NumberParam, [name: "minimum_reference_approval_score", maybe: true]},
		:minimum_turnout => {Plugs.NumberParam, [name: "minimum_voting_power", maybe: true]},
	},
	def update(conn, params = %{:user => user}) do
		params = if params.vote_weight_halving_days >= 1000 do
			Map.put(params, :vote_weight_halving_days, nil)
		else
			params
		end
		
		result = Identity.update_preferences(Identity.update_changeset(user, params
			|> Map.take([:trust_metric_url, :minimum_turnout, :vote_weight_halving_days, :approval_turnout_importance, :approval_minimum_score])))

		result |> handle_errors(conn, fn _user ->
			conn
			|> put_flash(:info, "Using your new preferences when calculating results.")
			|> redirect(to: default_redirect conn)
		end)
	end)

	defp prepare_poll(poll, data) do
		Map.merge(Map.merge(%{
			:references => [],
			:choice => nil,
			:for_choice => nil
		}, poll), data)
	end

	defp expand_poll(poll, calculation_opts) do
		case poll.kind do
			"custom" ->
				[prepare_poll(poll, %{:choice => poll.choice})]
			"is_reference" ->
				reference = Reference
				|> Repo.get_by!(for_choice_poll_id: poll.id)
				|> Repo.preload([:poll, :reference_poll])
				for_choice = poll.choice["main"]

				[
					prepare_poll(reference.poll, %{:references => [%{
						:reference_poll => reference.reference_poll,
						:for_choice => for_choice,
						:poll => reference.reference_poll
					}]}),
					prepare_poll(reference.reference_poll, %{})
				]
			_ ->
				[prepare_poll(poll, %{})]
		end
	end
end
