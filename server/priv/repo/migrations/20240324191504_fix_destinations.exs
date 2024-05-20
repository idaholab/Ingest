defmodule Ingest.Repo.Migrations.FixDestinations do
  use Ecto.Migration

  def change do
    alter table(:destinations) do
      add :azure_config_final, :map
      add :s3_config_final, :map
    end

    rename table(:destinations), :azure_config, to: :azure_config_staging
    rename table(:destinations), :s3_config, to: :s3_config_staging
  end
end
