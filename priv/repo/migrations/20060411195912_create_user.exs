defmodule Democracy.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
        add :username, :string
        add :token, :string

        add :name, :string

        add :is_trusted, :boolean
        add :voting_power, :float

      timestamps
    end

  end
end
