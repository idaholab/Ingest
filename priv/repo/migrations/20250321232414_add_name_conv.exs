defmodule Ingest.Repo.Migrations.AddNameConv do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :file_name_convention, {:array, :string}
    end
  end
end
