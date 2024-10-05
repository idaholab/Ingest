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

  # Users can manage their own projects
  def authorize(action, %{id: user_id} = _user, %{inserted_by: user_id} = _project)
      when action in [:update_project, :delete_project],
      do: :ok

  # Otherwise, denied
  def authorize(_, _, _), do: :error
end
