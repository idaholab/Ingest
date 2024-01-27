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
    field :public, :boolean, default: false
    field :status, Ecto.Enum, values: [:draft, :published]
    field :description, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by

    # even though these say "belongs_to" it really represents a one-to-one or many-to-one association
    many_to_many :templates, Template, join_through: "request_templates"
    many_to_many :projects, Project, join_through: "request_projects"
    many_to_many :destinations, Destination, join_through: "request_destinations"

    timestamps()
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [:name, :description, :status, :public, :inserted_by])
    |> validate_required([:name, :description])
  end
end
