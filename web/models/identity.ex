defmodule Liquio.Identity do
	use Liquio.Web, :model

	alias Liquio.Repo

	schema "identities" do
		field :username, :string
		field :password_hash, :string

		field :name, :string

		belongs_to :trust_metric_poll, Liquio.Poll
		has_many :trust_metric_poll_votes, through: [:trust_metric_poll, :votes]

		has_many :delegations_from, Liquio.Delegation, foreign_key: :from_identity_id
		has_many :delegations_to, Liquio.Delegation, foreign_key: :to_identity_id

		field :trust_metric_url, :string
		field :vote_weight_halving_days, :integer
		field :soft_quorum_t, :float
		field :minimum_reference_approval_score, :float
		field :minimum_voting_power, :float

		timestamps
	end
	
	def changeset(data, params) do
		if Map.has_key?(params, "username") and is_bitstring(params["username"]) do
			params = Map.put(params, "username", String.downcase(params["username"]))
		end
		if Map.has_key?(params, "name") and is_bitstring(params["name"]) do
			params = Map.put(params, "name", capitalize_name(params["name"]))
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
			:title => nil,
			:topics => nil,
		})

		changeset = changeset
		|> put_change(:trust_metric_poll_id, trust_metric_poll.id)
		Repo.insert(changeset)
	end

	def update_changeset(data, params) do
		data
		|> cast(params, ["trust_metric_url", "vote_weight_halving_days", "soft_quorum_t", "minimum_reference_approval_score", "minimum_voting_power"])
		|> validate_number(:vote_weight_halving_days, greater_than: 0)
		|> validate_number(:soft_quorum_t, greater_than_or_equal_to: 0)
		|> validate_number(:minimum_reference_approval_score, greater_than_or_equal_to: 0, less_than: 1)
		|> validate_number(:minimum_voting_power, greater_than: 0)
	end

	def update_preferences(changeset) do
		Repo.update(changeset)
	end

	def generate_password() do
		random_string(16)
	end

	defp random_string(length) do
		chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" |> String.split("")
		Enum.reduce((1..length), [], fn (_, acc) ->
			[Enum.random(chars) | acc]
		end) |> Enum.join("")
	end

	defp capitalize_name(name) do
		name |> String.downcase |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
	end
end
