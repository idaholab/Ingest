defmodule Ingest.Requests.Request do
  @moduledoc """
  This represents the full data request object. Consisting of a template, a project, and
  eventually a destination - this is the full package and root object when users are uploading
  files to the Ingest system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ingest.Destinations.Destination
  alias Ingest.Accounts.User
  alias Ingest.Projects.Project
  alias Ingest.Requests.Template

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "requests" do
    field :name, :string
    field :status, Ecto.Enum, values: [:draft, :published]
    field :description, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by
    belongs_to :project, Project, type: :binary_id, foreign_key: :project_id

    many_to_many :templates, Template, join_through: "request_templates"

    many_to_many :destinations, Destination,
      join_through: "request_destinations",
      join_keys: [request_id: :id, destination_id: :id]

    timestamps()
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [:name, :description, :status, :inserted_by, :project_id])
    |> validate_required([:name, :description, :project_id])
  end
end
