defmodule Ingest.Projects.ProjectMembers do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "project_members" do
    field :project_id, :binary_id
    field :member_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(project_member, attrs) do
    project_member
    |> cast(attrs, [:project_id, :member_id])
    |> validate_required([:project_id, :member_id])
  end
end
