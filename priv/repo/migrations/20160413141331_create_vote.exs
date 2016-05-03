defmodule Democracy.Repo.Migrations.CreateVote do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :weight, :float
      add :choice, :string
      add :max_power, :float
      add :poll_id, references(:polls, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps
    end
    create index(:votes, [:poll_id])
    create index(:votes, [:user_id])

  end
end
