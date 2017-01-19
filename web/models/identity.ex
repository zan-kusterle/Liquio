defmodule Liquio.Identity do
	use Liquio.Web, :model

	alias Liquio.Repo

	schema "identities" do
		field :email, :string
		field :username, :string
		field :name, :string
		
		has_many :trusted_by_identities, Liquio.Identity
		has_many :untrusted_by_identities, Liquio.Identity

		has_many :delegations_from, Liquio.Delegation, foreign_key: :from_identity_id
		has_many :delegations_to, Liquio.Delegation, foreign_key: :to_identity_id

		field :trust_metric_url, :string
		field :minimum_turnout, :float
		field :vote_weight_halving_days, :float
		field :reference_minimum_turnout, :float
		field :reference_minimum_agree, :float

		timestamps
	end
	
	def changeset(data, params) do
		params = if Map.has_key?(params, "username") and is_bitstring(params["username"]) do
			Map.put(params, "username", String.downcase(params["username"]))
		else
			params
		end
		params = if Map.has_key?(params, "name") and is_bitstring(params["name"]) do
			Map.put(params, "name", capitalize_name(params["name"]))
		else
			params
		end

		data
		|> cast(params, ["username", "name"])
		|> validate_required(:username)
		|> validate_required(:name)
		|> unique_constraint(:username)
		|> validate_length(:username, min: 3, max: 20)
		|> validate_length(:name, min: 3, max: 255)
	end

	def create(changeset) do
		changeset = changeset
		Repo.insert!(changeset)
	end

	def update_changeset(data, params) do
		data
		|> cast(params, ["trust_metric_url", "minimum_turnout", "vote_weight_halving_days", "reference_minimum_turnout", "reference_minimum_agree"])
		|> validate_number(:minimum_turnout, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
		|> validate_number(:vote_weight_halving_days, greater_than_or_equal_to: 0)
		|> validate_number(:reference_minimum_turnout, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
		|> validate_number(:reference_minimum_agree, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
	end

	def update_preferences(changeset) do
		Repo.update(changeset)
	end

	def search(query, search_term) do
		pattern = "%#{search_term}%"
		from(i in query,
		where: ilike(i.name, ^pattern) or ilike(i.username, ^pattern),
		order_by: fragment("similarity(?, ?) DESC", i.username, ^search_term))
	end

	def generate_password() do
		random_string(16)
	end

	defp random_string(length) do
		chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" |> String.split("")
		Enum.join(Enum.reduce((1..length), [], fn (_, acc) ->
			[Enum.random(chars) | acc]
		end), "")
	end

	defp capitalize_name(name) do
		name |> String.downcase |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
	end

	def preload_wip(identity) do
		votes = from(v in Vote, where: v.identity_id == ^identity.id and v.is_last == true and not is_nil(v.data))
		|> Repo.all
		|> Repo.preload([:poll, :identity])

		voted_polls = votes |> Enum.map(fn(vote) ->
			vote.poll
			|> Map.put(:choice, vote.data.choice)
		end)

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
	end


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
