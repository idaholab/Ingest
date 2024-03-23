defmodule Ingest.Repo.Migrations.AddToTemplates do
  use Ecto.Migration

  def change do
    alter table(:metadata) do
      add :template_id, references(:templates, on_delete: :delete_all, type: :binary_id)
    end

    rename table(:metadata), :uploaded, to: :submitted

    create unique_index(:metadata, [:template_id, :upload_id])
  end
end
