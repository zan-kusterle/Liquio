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
		trusted_by_votes =  identity.trust_metric_poll_votes
		|> Repo.preload([:identity])
		|> Enum.filter(& &1.is_last and &1.data != nil)
		|> Enum.map(& Map.put(&1, :trust_identity, &1.identity))
		|> Enum.sort(& &1.trust_identity.username > &2.trust_identity.username)

		votes = from(v in Vote, where: v.identity_id == ^identity.id and v.is_last == true and not is_nil(v.data))
		|> Repo.all
		|> Repo.preload([:poll, :identity])

		voted_polls = votes |> Enum.map(fn(vote) ->
			vote.poll
			|> Map.put(:choice, vote.data.choice)
		end)

		is_human_votes = votes
		|> Enum.filter(& &1.poll.kind == "is_human")
		|> Enum.map(fn(vote) ->
			trust_identity = Repo.get_by!(Identity, trust_metric_poll_id: vote.poll.id)
			Map.put(vote, :trust_identity, trust_identity)
		end)
		|> Enum.sort(& &1.trust_identity.username > &2.trust_identity.username)

		polls = voted_polls
		|> Enum.flat_map(&expand_poll/1)
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
		|> Map.values()

		vote_groups = if Enum.empty?(polls) do
			[]
		else
			root_polls = polls |> Enum.filter(fn(poll) ->
				Enum.all?(polls, fn current_poll ->
					Enum.find(current_poll.references, & &1.reference_poll.id == poll.id) == nil
				end)
			end)
			root_polls = if Enum.empty?(root_polls) do
				[Enum.at(polls, 0)]
			else
				root_polls
			end

			polls_by_ids = for poll <- polls, into: %{} do
				{poll.id, poll}
			end
			root_polls |> Enum.map(fn poll ->
				traverse_polls(polls_by_ids, poll.id, MapSet.new, 0, nil)
			end)
		end

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
			trusted_by_votes: trusted_by_votes,
			is_human_votes: is_human_votes,
			votes: votes,
			vote_groups: vote_groups)
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

	defp prepare_poll(poll, data) do
		Map.merge(Map.merge(%{
			:references => [],
			:choice => nil,
			:for_choice => nil
		}, poll), data)
	end

	defp expand_poll(poll) do
		case poll.kind do
			"custom" ->
				[prepare_poll(poll, %{:choice => poll.choice})]
			"is_reference" ->
				reference = Reference
				|> Repo.get_by!(for_choice_poll_id: poll.id)
				|> Repo.preload([:poll, :reference_poll])

				[
					prepare_poll(reference.poll, %{:references => [%{
						:reference_poll => reference.reference_poll,
						:for_choice => poll.choice,
						:poll => reference.poll
					}]}),
					prepare_poll(reference.reference_poll, %{})
				]
			_ ->
				[]
		end
	end
end
