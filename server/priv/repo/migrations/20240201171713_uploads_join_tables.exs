defmodule Ingest.Repo.Migrations.UploadsJoinTables do
  use Ecto.Migration

  def change do
    create table(:request_uploads, primary_key: false) do
      add :request_id, references(:requests, on_delete: :delete_all, type: :binary_id)
      add :upload_id, references(:uploads, on_delete: :delete_all, type: :binary_id)
    end

    create index(:request_uploads, [:request_id])
    create index(:request_uploads, [:upload_id])
  end
end
