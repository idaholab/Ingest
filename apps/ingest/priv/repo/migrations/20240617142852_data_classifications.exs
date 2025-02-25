defmodule Ingest.Repo.Migrations.DataClassifications do
  use Ecto.Migration

  def change do
    alter table(:destinations) do
      add :classifications_allowed, {:array, :string}
    end
  end
end
