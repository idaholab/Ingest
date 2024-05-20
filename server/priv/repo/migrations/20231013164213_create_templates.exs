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

    # we add a searchable field and assign a weight to it - allows for full-text search
    execute """
      ALTER TABLE templates
        ADD COLUMN searchable tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(description, '')), 'B')
        ) STORED;
    """

    execute """
      CREATE INDEX templates_searchable_idx ON templates USING gin(searchable);
    """

    create index(:templates, [:inserted_by])
  end
end
