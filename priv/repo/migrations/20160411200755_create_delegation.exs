defmodule Democracy.Repo.Migrations.CreateDelegation do
  use Ecto.Migration

  def change do
    create table(:delegations) do
      add :from_user_id, references(:users, on_delete: :nothing)
      add :to_user_id, references(:users, on_delete: :nothing)

      add :weight, :float

      timestamps
    end
    create index(:delegations, [:from_user_id])
    create index(:delegations, [:to_user_id])

  end
end
