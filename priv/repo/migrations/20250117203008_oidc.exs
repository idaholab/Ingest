defmodule Ingest.Repo.Migrations.Oidc do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :identity_provider_id, :string
    end
  end
end
