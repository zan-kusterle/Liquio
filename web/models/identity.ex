defmodule Democracy.Identity do
	use Democracy.Web, :model

	schema "identities" do
		field :username, :string
		field :token, :string # TODO: Hash and salt tokens

		field :name, :string

		belongs_to :trust_metric_poll, Democracy.Poll

		has_many :delegations_from, Democracy.Delegation, foreign_key: :from_identity_id
		has_many :delegations_to, Democracy.Delegation, foreign_key: :to_identity_id

		timestamps
	end

	@required_fields ~w(username name)
	@optional_fields ~w()

	def changeset(model, params \\ :empty) do
		model
		|> cast(params, @required_fields, @optional_fields)
		|> unique_constraint(:username)
	end

	def new(params, trust_metric_poll) do
		changeset(%Democracy.Identity{
			:token => generate_token(),
			:trust_metric_poll_id => trust_metric_poll.id
		}, params)
	end

	def generate_token() do
		random_string(16)
	end

	def random_string(length) do
		:crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
	end
end
