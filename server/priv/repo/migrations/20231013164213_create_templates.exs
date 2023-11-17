defmodule Ingest.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :fields, :map
      add :inserted_by, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:templates, [:inserted_by])
  end
end
