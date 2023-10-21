defmodule Ingest.Repo.Migrations.CreatePolicies do
  use Ecto.Migration

  def change do
    create table(:policies, primary_key: false) do
      add :id, :binary_id, primary_key: true
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
