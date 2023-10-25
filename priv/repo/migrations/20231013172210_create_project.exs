defmodule Ingest.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :inserted_by, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:projects, [:inserted_by])
  end
end
