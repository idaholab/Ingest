defmodule Ingest.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests) do
      add :name, :string
      add :description, :string
      add :status, :string
      add :public, :boolean, default: false, null: false
      add :template_id, references(:templates, on_delete: :nothing, type: :binary_id)
      add :project_id, references(:projects, on_delete: :nothing, type: :binary_id)
      add :inserted_by, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:requests, [:template_id])
    create index(:requests, [:project_id])
    create index(:requests, [:inserted_by])
  end
end
