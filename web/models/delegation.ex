defmodule Democracy.Delegation do
    use Democracy.Web, :model

    schema "delegations" do
        belongs_to :from_user, Democracy.User
        belongs_to :to_user, Democracy.User

        field :weight, :float

        timestamps
    end

    @required_fields ~w(from_user_id to_user_id weight)
    @optional_fields ~w()
    
    def changeset(model, params \\ :empty) do
        model
        |> cast(params, @required_fields, @optional_fields)
    end
end
