defmodule Democracy.Identity do
	use Democracy.Web, :model

	alias Democracy.Repo

	schema "identities" do
		field :username, :string
		field :token, :string # TODO: Hash and salt tokens

		field :name, :string

		belongs_to :trust_metric_poll, Democracy.Poll

		has_many :delegations_from, Democracy.Delegation, foreign_key: :from_identity_id
		has_many :delegations_to, Democracy.Delegation, foreign_key: :to_identity_id

		timestamps
	end
	
	def changeset(model, params \\ :empty) do
		model
		|> cast(params, ["username", "name"], [])
		|> unique_constraint(:username)
		|> validate_length(:username, min: 3, max: 20)
		|> validate_length(:name, min: 3, max: 255)
	end

	def create(changeset) do
		trust_metric_poll = Repo.insert!(%Democracy.Poll{
			:kind => "is_human",
			:title => nil,
			:choices => ["true"],
			:topics => nil,
			:is_direct => true
		})

		changeset = changeset
		|> put_change(:token, generate_token())
		|> put_change(:trust_metric_poll_id, trust_metric_poll.id)
		Repo.insert(changeset)
	end

	defp generate_token() do
		random_string(16)
	end

	defp random_string(length) do
		:crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
	end
end
