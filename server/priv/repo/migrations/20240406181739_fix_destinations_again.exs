defmodule Ingest.Repo.Migrations.FixDestinationsAgain do
  use Ecto.Migration

  def change do
    alter table(:destinations) do
      remove :azure_config_final
      remove :s3_config_final
    end

    rename table(:destinations), :azure_config_staging, to: :azure_config
    rename table(:destinations), :s3_config_staging, to: :s3_config
  end
end
