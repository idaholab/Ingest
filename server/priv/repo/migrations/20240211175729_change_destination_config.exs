defmodule Ingest.Repo.Migrations.ChangeDestinationConfig do
  use Ecto.Migration

  def change do
    alter table(:destinations) do
      add :temporary_config, :binary
    end

    create table(:metadata, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uploaded, :boolean, default: false, null: false
      add :data, :binary
      add :upload_id, references(:uploads, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:metadata, [:upload_id])
  end
end
