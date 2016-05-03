defmodule Democracy.User do
    use Democracy.Web, :model

    schema "users" do
        field :name, :string

        field :username, :string
        field :token, :string # TODO: Hash tokens

        field :is_trusted, :boolean
        field :voting_power, :float

        has_many :delegations_from, Democracy.Delegation, foreign_key: :from_user_id
        has_many :delegations_to, Democracy.Delegation, foreign_key: :to_user_id

        timestamps
    end

    @required_fields ~w(name)
    @optional_fields ~w()

    def changeset(model, params \\ :empty) do
        model
        |> cast(params, @required_fields, @optional_fields)
    end

    def generate_username() do
        random_string(16)
    end

    def generate_token() do
        random_string(16)
    end

    def random_string(length) do
        :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
    end
end
