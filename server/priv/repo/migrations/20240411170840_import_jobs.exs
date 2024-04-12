defmodule Ingest.Repo.Migrations.ImportJobs do
  use Ecto.Migration

  def change do
    create table(:import_jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :inserted_by, references(:users, on_delete: :delete_all, type: :binary_id)
      add :errors, {:array, :string}
      add :status, :string
      add :box_config, :map
      add :standard_config, :map
      add :request_id, :binary_id

      timestamps()
    end
  end
end
