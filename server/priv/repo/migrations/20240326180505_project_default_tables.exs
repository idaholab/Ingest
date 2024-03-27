defmodule Ingest.Repo.Migrations.ProjectDefaultTables do
  use Ecto.Migration

  def change do
    create table(:project_templates, primary_key: false) do
      add :project_id, references(:projects, on_delete: :delete_all, type: :binary_id)
      add :template_id, references(:templates, on_delete: :delete_all, type: :binary_id)
    end

    create table(:project_destinations, primary_key: false) do
      add :project_id, references(:projects, on_delete: :delete_all, type: :binary_id)
      add :destination_id, references(:destinations, on_delete: :delete_all, type: :binary_id)
    end

    create index(:project_templates, [:project_id])
    create index(:project_destinations, [:project_id])
  end
end
