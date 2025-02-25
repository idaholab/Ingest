defmodule Ingest.Projects.Project do
  @moduledoc """
  Project represents a group of individuals with common access to destinations and templates.
  """
  @behaviour Bodyguard.Policy

  use Ecto.Schema
  import Ecto.Changeset
  alias Ingest.Destinations.Destination
  alias Ingest.Projects.ProjectInvites
  alias Ingest.Accounts.User
  alias Ingest.Requests.Request
  alias Ingest.Requests.Template

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    field :description, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by
    has_many :requests, Request, foreign_key: :project_id
    has_many :invites, ProjectInvites, foreign_key: :project_id

    many_to_many :project_members, Ingest.Accounts.User,
      join_through: "project_members",
      join_keys: [project_id: :id, member_id: :id]

    many_to_many :templates, Template, join_through: "project_templates"

    many_to_many :destinations, Destination,
      join_through: "project_destinations",
      join_keys: [project_id: :id, destination_id: :id]

    timestamps()
  end

  @doc false
  def changeset(project, attrs, _metadata \\ %{}) do
    project
    |> cast(attrs, [:name, :description, :inserted_by])
    |> validate_required([:name, :description])
  end

  # Anyone can make a project
  def authorize(:create_project, _user), do: :ok

  # Admins can do anything
  def authorize(action, %{roles: :admin} = _user, _project)
      when action in [:update_project, :delete_project],
      do: :ok

  # Users can manage their own projects or ones they are maintainers on
  def authorize(
        action,
        %{id: user_id} = _user,
        %{id: project_id, inserted_by: owner} = _project
      )
      when action in [:update_project, :delete_project] do
    member = Ingest.Projects.get_member_project(user_id, project_id)

    if member do
      Enum.member?([:manager, :owner], member.role) || user_id == owner
    else
      user_id == owner
    end
  end

  # Users can view their own projects or ones they are members of
  def authorize(
        action,
        %{id: user_id} = _user,
        %{id: project_id, inserted_by: owner} = _project
      )
      when action in [:view_project] do
    member = Ingest.Projects.get_member_project(user_id, project_id)

    if member do
      true
    else
      user_id == owner
    end
  end

  # Otherwise, denied
  def authorize(_, _, _), do: :error
end

defmodule Ingest.Projects.ProjectSearch do
  @moduledoc """
  Reflects the virtual table for FTS5 trigram searching.
  """
  use Ecto.Schema

  @primary_key false
  schema "projects_search" do
    field :rowid, :integer
    field :id, :binary_id
    field :name, :string
    field :description, :string
    field :rank, :float, virtual: true
  end
end

defmodule Ingest.Projects.ProjectDestination do
  @moduledoc """
  This structure allows us to add more data to the join of destinations to
  their projects if needed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "project_destinations" do
    belongs_to :project, Ingest.Projects.Project, foreign_key: :project_id, type: :binary_id

    belongs_to :destination, Ingest.Destinations.Destination,
      foreign_key: :destination_id,
      type: :binary_id

    # this field can be any of the additional configurations per type, found
    # in the destination schema file itself. It relies on the destination type
    # to know what additional config to choose
    field :additional_config, :map
  end

  @doc false
  def changeset(request_destination, attrs) do
    request_destination
    |> cast(attrs, [:project_id, :destination_id])
    |> validate_required([:project_id, :destination_id])
  end
end
