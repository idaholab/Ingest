defmodule Ingest.Repo.Migrations.RemoveUnusedTables do
  use Ecto.Migration

  def change do
    drop table(:upload_metadatas)
  end
end
