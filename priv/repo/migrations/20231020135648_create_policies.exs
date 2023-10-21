defmodule Ingest.Repo.Migrations.CreatePolicies do
  use Ecto.Migration

  def change do
    create table(:policies) do
      add :name, :string
      add :actions, {:array, :string}
      add :resource_types, {:array, :string}
      add :scope, :string
      add :scope_id, :binary_id
      add :attributes, :map
      add :matcher, :string

      timestamps()
    end
  end
end
