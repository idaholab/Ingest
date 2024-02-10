defmodule Ingest.Projects.ProjectInvites do
  alias Ingest.Accounts.User
  alias Ingest.Projects.Project
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "project_invites" do
    field :email, :string
    belongs_to :project, Project, type: :binary_id, foreign_key: :project_id
    belongs_to :invited_user, User, type: :binary_id, foreign_key: :invited_user_id

    timestamps()
  end

  @doc false
  def changeset(project_invites, attrs) do
    project_invites
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end

  @doc false
  def email_changeset(project_invites, attrs) do
    project_invites
    |> cast(attrs, [:email])
    |> Ingest.Accounts.User.validate_email(%{validate_email: false})
    |> validate_required([:email])
  end
end
