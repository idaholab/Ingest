defmodule Ingest.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string
      add :action_link, :string
      add :body, :string
      add :seen, :boolean, default: false, null: false

      add :user_id,
          references(:users, on_delete: :delete_all, on_update: :update_all, type: :binary_id)

      timestamps()
    end

    create index(:notifications, [:user_id])
  end
end
