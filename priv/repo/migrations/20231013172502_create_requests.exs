defmodule Ingest.Repo.Migrations.CreateRequests do
  use Ecto.Migration

  def change do
    create table(:requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :string
      add :status, :string, default: "draft"
      add :visibility, :string, default: "private"
      add :allowed_email_domains, {:array, :string}

      add :inserted_by,
          references(:users, on_delete: :delete_all, on_update: :update_all, type: :binary_id)

      add :project_id,
          references(:projects, on_delete: :delete_all, on_update: :update_all, type: :binary_id)

      timestamps()
    end

    create index(:requests, [:inserted_by])
  end
end
