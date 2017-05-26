defmodule Liquio.Vote do
	use Ecto.Schema
	use Timex.Ecto.Timestamps
	import Ecto.Query, only: [from: 2]
	alias Liquio.{Repo, Vote, Signature, Identity}

	schema "votes" do
		belongs_to :signature, Liquio.Signature
		field :username, :string

		field :path, {:array, :string}

		field :unit, :string
		field :choice, :float
		
		field :at_date, Timex.Ecto.Date
		timestamps(inserted_at: :datetime, updated_at: false, usec: true)
		field :to_datetime, Timex.Ecto.DateTime

		field :group_key, :string
		field :search_text, :string
	end

	def group_key(%{:path => path, :unit => unit, :at_date => at_date}) do
		path_normalized = path |> Enum.join("/") |> String.downcase
		"#{path_normalized}___#{encode_unit(unit) |> String.downcase}___#{Timex.format!(at_date, "{YYYY}-{0M}-{0D}")}"
	end

	def decode_unit!(value) do
		parts = value |> String.trim |> String.split("-") |> Enum.map(&String.trim/1) |> Enum.filter(& String.length(&1) >= 1)
		
		unit = if Enum.count(parts) == 2 do
			%{
				:type => :spectrum,
				:key => String.downcase(Enum.at(parts, 0)),
				:positive => Enum.at(parts, 0),
				:negative => Enum.at(parts, 1),
				:value => "#{Enum.at(parts, 0)}-#{Enum.at(parts, 1)}"
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
							:unit => right,
							:value => "#{left}(#{right})"
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
					:unit => nil,
					:value => m
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

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.search_text, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.search_text, ^search_term))
	end

	def get_at_datetime(path, datetime) do
		{path_where, path_params} = if path do
			q = path |> Enum.with_index |> Enum.map(fn({_value, index}) ->
				"lower(v.path[#{index + 1}]) = $#{index + 1}"
			end) |> Enum.join(" AND ")
			{"#{q} AND", Enum.map(path, & String.downcase(&1))}
		else
			{"", []}
		end

		query = "SELECT *
			FROM votes AS v
			WHERE #{path_where}
				v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}' AND
				(v.to_datetime IS NULL OR v.to_datetime >='#{Timex.format!(datetime, "{ISO:Basic}")})')
			ORDER BY v.datetime;"
		res = Ecto.Adapters.SQL.query!(Repo, query, path_params)
		cols = Enum.map res.columns, &(String.to_atom(&1))
		votes = res.rows
		|> Enum.map(fn(row) ->
			vote = struct(Liquio.Vote, Enum.zip(cols, row))
			{date, {h, m, s, _}} = vote.datetime
			vote = Map.put(vote, :datetime, Timex.to_naive_datetime({date, {h, m, s}}))
			vote = Map.put(vote, :at_date, Timex.to_date(vote.at_date))
			vote
		end)
		|> Enum.filter(& &1.choice != nil)

		votes
	end

	def current_by(username, node) do
		from(v in Vote, where:
			v.path == ^node.path and
			v.username == ^username and
			is_nil(v.to_datetime)
		) |> Repo.all
	end

	def set(node, public_key, signature, unit, at_date, choice) do
		group_key = Vote.group_key(%{path: node.path, unit: unit, at_date: at_date})

		username = Identity.username_from_key(public_key)
		message = "#{username} #{Enum.join(node.path, "/")} #{unit.value} #{:erlang.float_to_binary(choice, decimals: 5)}"

		signature = Signature.add!(public_key, message, signature)

		now = Timex.now
		from(v in Vote,
			where: v.group_key == ^group_key and
				v.username == ^username and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])
		
		result = Repo.insert!(%Vote{
			:signature_id => signature.id,

			:username => username,

			:path => node.path,
			:group_key => group_key,
			:search_text => Enum.join(node.path, " "),

			:unit => Vote.encode_unit(unit),
			:choice => choice,
			
			:to_datetime => nil,
			:at_date => at_date
		})

		result
	end

	def delete(node, public_key, signature, unit, at_date) do
		group_key = Vote.group_key(%{path: node.path, unit: unit, at_date: at_date})

		username = Identity.username_from_key(public_key)
		message = "#{username} #{Enum.join(node.path, "/")} #{unit.value}"

		signature = Signature.add!(public_key, message, signature)
		
		now = Timex.now
		from(v in Vote,
			where: v.group_key == ^group_key and
				v.username == ^username and
				is_nil(v.to_datetime),
			update: [set: [to_datetime: ^now]])
		|> Repo.update_all([])
	end
end