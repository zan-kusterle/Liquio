defmodule Liquio.Vote do
	use Liquio.Web, :model

	schema "votes" do
		belongs_to :identity, Liquio.Identity

		field :path, {:array, :string}

		field :unit, :string
		field :choice, :float
		
		field :at_date, Timex.Ecto.Date
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :is_last, :boolean

		field :group_key, :string
		field :search_text, :string
	end

	def group_key(%{:path => path, :unit => unit, :at_date => at_date}) do
		path_normalized = path |> Enum.join("/") |> String.downcase
		"#{path_normalized}___#{encode_unit(unit)}___#{Timex.format!(at_date, "{YYYY}-{0M}-{0D}")}"
	end

	def decode_unit!(value) do
		parts = value |> String.trim |> String.split("-") |> Enum.map(&String.trim/1) |> Enum.filter(& String.length(&1) >= 1)
		
		unit = if Enum.count(parts) == 2 do
			%{
				:type => :spectrum,
				:key => String.downcase(Enum.at(parts, 0)),
				:positive => Enum.at(parts, 0),
				:negative => Enum.at(parts, 1)
			}
		else
			case String.split(value, "(", parts: 2) do
				[left, right] ->
					left = String.trim(left)
					right = String.trim(right)
					
					if String.ends_with?(right, ")") and String.length(right) >= 2 and String.length(left) >= 3 do
						right = String.slice(right, 0, String.length(right) - 1)

						%{
							:type => :quantity,
							:key => String.downcase(left),
							:measurement => left,
							:unit => right
						}
					else
						nil
					end
				[_] -> nil
			end
		end

		if unit do
			unit
		else
			m = Enum.join(parts, "-")
			if String.length(m) >= 3 do
				%{
					:type => :quantity,
					:key => String.downcase(m),
					:measurement => m,
					:unit => nil
				}
			else
				raise "Unable to decode unit #{value}"
			end
		end
	end

	def encode_unit(%{:type => type, :positive => positive, :negative => negative}) when type == :spectrum do
		"#{positive}-#{negative}"
	end
	def encode_unit(%{:type => type, :measurement => measurement, :unit => unit}) when type == :quantity do
		if unit do
			"#{measurement} (#{unit})"
		else
			measurement
		end
	end
end