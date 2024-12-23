defmodule Ingest.Repo.Migrations.DestinationMembersPrimaryKey do
  use Ecto.Migration

  def change do
    drop table(:destination_members)

    create table(:destination_members) do
      add :role, :string, null: true
      add :email, :string, null: true
      add :status, :string, default: nil

      add :project_id,
          references(:projects, on_delete: :delete_all, on_update: :update_all, type: :binary_id)

      add :request_id,
          references(:requests, on_delete: :delete_all, on_update: :update_all, type: :binary_id)

      add :destination_id,
          references(:destinations,
            on_delete: :delete_all,
            on_update: :update_all,
            type: :binary_id
          )

      add :user_id,
          references(:users, on_delete: :nilify_all, on_update: :update_all, type: :binary_id)

      timestamps()
    end

    create index(:destination_members, [:destination_id])
    create index(:destination_members, [:user_id])
  end
end
