defmodule Ingest.Repo.Migrations.JoinTables do
  use Ecto.Migration

  def change do
    create table(:request_templates, primary_key: false) do
      add :request_id, references(:requests, on_delete: :delete_all, type: :binary_id)
      add :template_id, references(:templates, on_delete: :delete_all, type: :binary_id)
    end

    create table(:request_projects, primary_key: false) do
      add :request_id, references(:requests, on_delete: :delete_all, type: :binary_id)
      add :project_id, references(:projects, on_delete: :delete_all, type: :binary_id)
    end

    create table(:request_destinations, primary_key: false) do
      add :request_id, references(:requests, on_delete: :delete_all, type: :binary_id)
      add :destination_id, references(:destinations, on_delete: :delete_all, type: :binary_id)
    end

    create index(:request_templates, [:request_id])
    create index(:request_projects, [:request_id])
    create index(:request_destinations, [:request_id])
  end
end
