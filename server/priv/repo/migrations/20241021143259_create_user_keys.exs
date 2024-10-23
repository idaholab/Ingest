defmodule Ingest.Repo.Migrations.CreateUserKeys do
  use Ecto.Migration

  def change do
    create table(:user_keys, primary_key: false) do
      add :access_key, :string, primary_key: true
      add :secret_key, :binary
      add :expires, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:user_keys, [:user_id, :access_key])
  end
end
