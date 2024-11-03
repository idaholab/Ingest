defmodule Ingest.Repo.Migrations.Lakefs do
  use Ecto.Migration

  def change do
    alter table(:destinations) do
      add :lakefs_config, :binary
    end
  end
end
