defmodule Ingest.Repo.Migrations.UserRoles do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :roles, :string, default: "member"
      add :identity_provider, :string, default: "internal"
    end
  end
end
