defmodule Ingest.Repo.Migrations.CreateRequestMembers do
  use Ecto.Migration

  def change do
    create table(:request_members, primary_key: false) do
      add :request_id, :binary_id, foreign_key: true
      add :email, :string, primary_key: true
      timestamps()
    end
  end
end
