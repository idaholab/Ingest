defmodule Ingest.Repo.Migrations.CreateUploads do
  use Ecto.Migration

  def change do
    create table(:uploads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :ext, :string
      add :size, :integer
      add :uploaded_by, references(:users, on_delete: :nothing, type: :binary_id)
      add :request_id, references(:requests, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create table(:upload_metadatas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :binary
      add :uploaded, :boolean
      add :upload_id, references(:uploads, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:upload_metadatas, [:upload_id])
    create index(:uploads, [:uploaded_by])
    create index(:uploads, [:request_id])
  end
end
