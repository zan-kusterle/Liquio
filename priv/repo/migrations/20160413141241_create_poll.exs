defmodule Democracy.Repo.Migrations.CreatePoll do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :app_id, :string

      add :name, :string

      timestamps
    end

  end
end
