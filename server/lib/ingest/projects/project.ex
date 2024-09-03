defmodule Ingest.Projects.Project do
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
  def changeset(project, attrs, metadata \\ %{}) do
    project
    |> cast(attrs, [:name, :description, :inserted_by])
    |> validate_required([:name, :description])
  end
end
