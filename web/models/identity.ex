defmodule Liquio.Identity do
	use Liquio.Web, :model

	alias Liquio.Repo

	schema "identities" do
		field :email, :string
		field :username, :string
		field :name, :string

		belongs_to :trust_metric_poll, Liquio.Poll
		has_many :trust_metric_poll_votes, through: [:trust_metric_poll, :votes]

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
		trust_metric_poll = Repo.insert!(%Liquio.Poll{
			:kind => "is_human",
			:choice_type => "probability",
			:title => nil
		})

		changeset = changeset
		|> put_change(:trust_metric_poll_id, trust_metric_poll.id)
		Repo.insert(changeset)
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
end
