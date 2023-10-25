defmodule Ingest.Repo.Migrations.CreateProjectMembers do
  use Ecto.Migration

  def change do
    create table(:project_members, primary_key: false) do
      add :project_id, references(:projects, on_delete: :nothing, type: :binary_id)
      add :member_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:project_members, [:project_id])
  end
end
