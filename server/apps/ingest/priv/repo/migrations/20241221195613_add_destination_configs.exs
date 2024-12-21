defmodule Ingest.Repo.Migrations.AddDestinationConfigs do
  use Ecto.Migration

  def change do
    alter table(:request_destinations) do
      add :additional_config, :binary
    end

    alter table(:project_destinations) do
      add :additional_config, :binary
    end
  end
end
