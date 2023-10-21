defmodule Ingest.Repo.Migrations.CreateResourcePolicies do
  use Ecto.Migration

  def change do
    create table(:resource_policies) do
      add :resource_id, :uuid
      add :resource_type, :string
      add :policy_id, references(:policies, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:resource_policies, [:policy_id])
  end
end
