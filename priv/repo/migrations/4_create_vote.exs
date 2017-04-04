defmodule Liquio.Repo.Migrations.CreateVote do
	use Ecto.Migration

	# transforming 1-n to 1-1 for 99.9% cases. 
	# this basically lets voters vote on unit for each text. everyone else has cleaner urls, less url confusion
	# most NOUNS have 1 unit, that is by far the most logical. in some cases multiple units might be applicable (e.g. Sun Temperature/Volume)
	# make unit optional param, select most voted by default
	# remove meta option, that functionallity is now basically in options (minimum turnout ratio). so for some TEXTS voters simply shouldnt vote (e.g. science, global warming - too broad)
	# for choice replaced with factor analysis??
	# TODO: Units in embed
	# This simplifies node-input since people dont need to select choice type in advance (reference is true for all choice types). Remove meta, merge search and create (if no results, simply go to url)
	def change do
		create table(:votes) do
			add :identity_id, references(:identities, on_delete: :nothing), null: false

			add :path, {:array, :string}, null: false
			add :group_key, :string, null: false

			add :unit, :string, null: false
			add :is_probability, :boolean, default: false
			add :choice, :float, null: true
			add :at_date, :date, null: false
			
			add :datetime, :utc_datetime, null: false
			add :is_last, :boolean, null: false
			add :search_text, :string, null: false
		end

		create index(:votes, [:identity_id])
		create index(:votes, [:choice_type])
		create index(:votes, [:group_key])
		create index(:votes, [:datetime])
		create index(:votes, [:is_last])
	end
end
