defmodule Ingest.Projects.ProjectMembers do
  alias Ingest.Accounts.User
  alias Ingest.Projects.Project
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "project_members" do
    belongs_to :user, User, type: :binary_id, foreign_key: :member_id
    belongs_to :project, Project, type: :binary_id, foreign_key: :project_id
    timestamps()
  end

  @doc false
  def changeset(project_member, attrs) do
    project_member
    |> cast(attrs, [:project_id, :member_id])
    |> validate_required([:project_id, :member_id])
  end
end
