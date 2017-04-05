defmodule Liquio.Vote do
	use Liquio.Web, :model

	schema "votes" do
		belongs_to :identity, Liquio.Identity

		field :path, {:array, :string}

		field :unit, :string
		field :is_probability, :boolean
		field :choice, :float
		
		field :at_date, Timex.Ecto.Date
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		field :group_key, :string
		field :search_text, :string
	end
end