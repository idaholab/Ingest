defmodule Ingest.Repo.Migrations.CreateProjectInvites do
  use Ecto.Migration

  def change do
    create table(:project_invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :project_id, references(:projects, on_delete: :delete_all, type: :binary_id)
      add :invited_user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:project_invites, [:project_id])
    create index(:project_invites, [:invited_user_id])
  end
end
