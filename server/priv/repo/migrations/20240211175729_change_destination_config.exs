defmodule Ingest.Repo.Migrations.ChangeDestinationConfig do
  use Ecto.Migration

  def change do
    alter table(:destinations) do
      add :temporary_config, :map
    end

    create table(:metadata, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :uploaded, :boolean, default: false, null: false
      add :data, :map
      add :upload_id, references(:uploads, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:metadata, [:upload_id])
  end
end
