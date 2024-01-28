defmodule Ingest.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :inserted_by, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    execute """
      ALTER TABLE projects
        ADD COLUMN searchable tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(description, '')), 'B')
        ) STORED;
    """

    execute """
      CREATE INDEX projects_searchable_idx ON projects USING gin(searchable);
    """

    create index(:projects, [:inserted_by])
  end
end
