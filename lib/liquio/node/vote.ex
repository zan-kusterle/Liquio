defmodule Liquio.Vote do
	use Liquio.Web, :model
	alias Liquio.{Repo, Node, NodeRepo, Vote}

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

	def search(query, search_term) do
		from(v in query,
		where: fragment("? % ?", v.search_text, ^search_term),
		order_by: fragment("similarity(?, ?) DESC", v.search_text, ^search_term))
	end

	def get_at_datetime(path, datetime) do
		query = "SELECT DISTINCT ON (v.identity_id) *
			FROM votes AS v
			WHERE v.group_key = $1 AND v.datetime <= '#{Timex.format!(datetime, "{ISO:Basic}")}'
			ORDER BY v.identity_id, v.datetime DESC;"
		group_key = Node.group_key(%{path: path})
		res = Ecto.Adapters.SQL.query!(Repo, query , [group_key])
		cols = Enum.map res.columns, &(String.to_atom(&1))
		votes = res.rows
		|> Enum.map(fn(row) ->
			vote = struct(Liquio.Vote, Enum.zip(cols, row))
			{date, {h, m, s, _}} = vote.datetime
			vote = Map.put(vote, :datetime,  Timex.to_naive_datetime({date, {h, m, s}}))
			vote
		end)
		|> Enum.filter(& &1.choice != nil)
		|> Enum.map(& {&1.identity_id, &1}) |> Enum.into(%{})

		votes
	end

	def current_by(identity, node, unit, is_probability) do
		query = from(v in Vote, where:
			v.group_key == ^Node.group_key(node) and
			v.identity_id == ^identity.id and
			v.is_last
		)
		votes = Repo.all(query)
		if Enum.empty?(votes) or Enum.at(votes, 0).choice == nil do
			nil
		else
			Enum.at(votes, 0)
		end
	end

	def set(identity, node, unit, is_probability, choice) do
		from(v in Vote,
			where: v.group_key == ^Node.group_key(node) and
				v.identity_id == ^identity.id and
				v.is_last == true,
			update: [set: [is_last: false]])
		|> Repo.update_all([])
		result = Repo.insert!(%Vote{
			:identity_id => identity.id,

			:path => node.path,
			:group_key => Enum.join(node.path, "/"),
			:search_text => Enum.join(node.path, " "),

			:unit => unit,
			:is_probability => is_probability,
			:choice => choice,
			
			:is_last => true,
			:at_date => Timex.today()
		})

		NodeRepo.invalidate_cache(node)
		result
	end

	def delete(identity, node, unit, is_probability) do
		Vote.set(identity, node, unit, is_probability, nil)
	end
end