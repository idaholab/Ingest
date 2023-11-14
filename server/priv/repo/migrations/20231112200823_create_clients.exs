defmodule Ingest.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :name, :string
      add :token, :string
      add :owner_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:clients, [:owner_id])
  end
end
