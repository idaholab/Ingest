defmodule Ingest.Repo.Migrations.CreateDeeplynxDestination do
  use Ecto.Migration

  def change do
    alter table("destinations") do
      add(:deeplynx_config, :binary)
    end
  end
end
