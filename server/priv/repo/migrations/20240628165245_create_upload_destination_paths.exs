defmodule Ingest.Repo.Migrations.CreateUploadDestinationPaths do
  use Ecto.Migration

  def change do
    create table(:upload_destination_paths, primary_key: false) do
      add :path, :string
      add :upload_id, references(:uploads, on_delete: :nothing, type: :binary_id)
      add :destination_id, references(:destinations, on_delete: :nothing, type: :binary_id)
    end

    create index(:upload_destination_paths, [:upload_id])
    create index(:upload_destination_paths, [:destination_id])
  end
end
