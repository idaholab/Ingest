defmodule Ingest.Repo.Migrations.CreateTemplateMembers do
  use Ecto.Migration

  def change do
    create table(:template_members, primary_key: false) do
      add :role, :string, null: true
      add :email, :string, null: true
      add :template_id, references(:templates, on_delete: :delete_all, type: :binary_id)
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:template_members, [:template_id])
    create index(:template_members, [:user_id])
  end
end
