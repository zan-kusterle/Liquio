defmodule Democracy.Identity do
	use Democracy.Web, :model

	alias Democracy.Repo

	schema "identities" do
		field :username, :string
		field :token, :string # TODO: Hash and salt tokens

		field :name, :string

		belongs_to :trust_metric_poll, Democracy.Poll
		has_many :trust_metric_poll_votes, through: [:trust_metric_poll, :votes]

		has_many :delegations_from, Democracy.Delegation, foreign_key: :from_identity_id
		has_many :delegations_to, Democracy.Delegation, foreign_key: :to_identity_id

		field :trust_metric_url, :string
		field :vote_weight_halving_days, :integer
		field :soft_quorum_t, :float
		field :minimum_reference_approval_score, :float

		timestamps
	end
	
	def changeset(data, params) do
		data
		|> cast(params, ["username", "name"])
		|> validate_required(:username)
		|> validate_required(:name)
		|> unique_constraint(:username)
		|> validate_length(:username, min: 3, max: 20)
		|> validate_length(:name, min: 3, max: 255)
	end

	def create(changeset) do
		trust_metric_poll = Repo.insert!(%Democracy.Poll{
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
		|> cast(params, ["trust_metric_url", "vote_weight_halving_days", "soft_quorum_t", "minimum_reference_approval_score"])
		|> validate_number(:vote_weight_halving_days, greater_than: 0)
		|> validate_number(:soft_quorum_t, greater_than_or_equal_to: 0)
		|> validate_number(:minimum_reference_approval_score, greater_than_or_equal_to: 0, less_than: 1)
	end

	def update_preferences(changeset) do
		Repo.update(changeset)
	end

	def generate_token() do
		random_string(16)
	end

	defp random_string(length) do
		:crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
	end
end
