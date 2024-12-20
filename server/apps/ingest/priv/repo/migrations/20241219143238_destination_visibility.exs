defmodule Ingest.Repo.Migrations.DestinationVisibility do
  use Ecto.Migration

  def change do
    alter table(:destinations) do
      add :visibility, :string
    end

    create table(:destination_members, primary_key: false) do
      add :role, :string, null: true
      add :pending, :boolean, default: true

      add :destination_id,
          references(:destinations,
            on_delete: :delete_all,
            on_update: :update_all,
            type: :binary_id
          )

      add :user_id,
          references(:users, on_delete: :delete_all, on_update: :update_all, type: :binary_id)

      timestamps()
    end

    create index(:destination_members, [:destination_id])
    create index(:destination_members, [:user_id])
  end
end
