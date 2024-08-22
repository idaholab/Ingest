defmodule Ingest.Repo.Migrations.FixConstraints do
  use Ecto.Migration

  def change do
    alter table(:uploads) do
      modify :request_id, references(:requests, on_delete: :delete_all, type: :binary_id),
        from: references(:requests, on_delete: :nothing, type: :binary_id)

      modify :uploaded_by, references(:users, on_delete: :nilify_all, type: :binary_id),
        from: references(:requests, on_delete: :nothing, type: :binary_id)
    end

    alter table(:request_destinations) do
      modify :request_id, references(:requests, on_delete: :delete_all, type: :binary_id),
        from: references(:requests, on_delete: :nothing, type: :binary_id)

      modify :destination_id, references(:destinations, on_delete: :delete_all, type: :binary_id),
        from: references(:destinations, on_delete: :nothing, type: :binary_id)
    end

    alter table(:request_members) do
      modify :request_id, references(:requests, on_delete: :delete_all, type: :binary_id)
    end

    alter table(:request_templates) do
      modify :request_id, references(:requests, on_delete: :delete_all, type: :binary_id),
        from: references(:requests, on_delete: :nothing, type: :binary_id)

      modify :template_id, references(:templates, on_delete: :delete_all, type: :binary_id),
        from: references(:templates, on_delete: :nothing, type: :binary_id)
    end

    alter table(:request_uploads) do
      modify :request_id, references(:requests, on_delete: :delete_all, type: :binary_id),
        from: references(:requests, on_delete: :nothing, type: :binary_id)

      modify :upload_id, references(:uploads, on_delete: :delete_all, type: :binary_id),
        from: references(:uploads, on_delete: :nothing, type: :binary_id)
    end

    alter table(:project_templates) do
      modify :project_id, references(:projects, on_delete: :delete_all, type: :binary_id),
        from: references(:projects, on_delete: :nothing, type: :binary_id)

      modify :template_id, references(:templates, on_delete: :delete_all, type: :binary_id),
        from: references(:templates, on_delete: :nothing, type: :binary_id)
    end

    alter table(:project_members) do
      modify :project_id, references(:projects, on_delete: :delete_all, type: :binary_id),
        from: references(:projects, on_delete: :nothing, type: :binary_id)

      modify :member_id, references(:users, on_delete: :delete_all, type: :binary_id),
        from: references(:users, on_delete: :nothing, type: :binary_id)
    end

    alter table(:project_invites) do
      modify :project_id, references(:projects, on_delete: :delete_all, type: :binary_id),
        from: references(:projects, on_delete: :nothing, type: :binary_id)
    end

    alter table(:project_destinations) do
      modify :project_id, references(:projects, on_delete: :delete_all, type: :binary_id),
        from: references(:projects, on_delete: :nothing, type: :binary_id)

      modify :destination_id, references(:destinations, on_delete: :delete_all, type: :binary_id),
        from: references(:destinations, on_delete: :nothing, type: :binary_id)
    end

    alter table(:metadata) do
      modify :upload_id, references(:uploads, on_delete: :delete_all, type: :binary_id),
        from: references(:uploads, on_delete: :nothing, type: :binary_id)
    end

    alter table(:upload_destination_paths) do
      modify :upload_id, references(:uploads, on_delete: :delete_all, type: :binary_id),
        from: references(:uploads, on_delete: :nothing, type: :binary_id)

      modify :destination_id, references(:destinations, on_delete: :delete_all, type: :binary_id),
        from: references(:destinations, on_delete: :nothing, type: :binary_id)
    end
  end
end
