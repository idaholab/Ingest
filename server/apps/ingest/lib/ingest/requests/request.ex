defmodule Ingest.Requests.Request do
  @moduledoc """
  This represents the full data request object. Consisting of a template, a project, and
  eventually a destination - this is the full package and root object when users are uploading
  files to the Ingest system.
  """
  @behaviour Bodyguard.Policy

  use Ecto.Schema
  import Ecto.Changeset

  alias Ingest.Uploads.Upload
  alias Ingest.Destinations.Destination
  alias Ingest.Accounts.User
  alias Ingest.Projects.Project
  alias Ingest.Requests.Template

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "requests" do
    field :name, :string
    field :status, Ecto.Enum, values: [:draft, :published]
    field :visibility, Ecto.Enum, values: [:public, :private, :internal]
    field :description, :string
    field :allowed_email_domains, {:array, :string}

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by
    belongs_to :project, Project, type: :binary_id, foreign_key: :project_id

    has_many :uploads, Upload, foreign_key: :request_id

    many_to_many :templates, Template, join_through: "request_templates"

    many_to_many :destinations, Destination,
      join_through: "request_destinations",
      join_keys: [request_id: :id, destination_id: :id]

    timestamps()
  end

  @doc false
  def changeset(request, attrs, _meta \\ %{}) do
    request
    |> cast(attrs, [
      :name,
      :description,
      :status,
      :inserted_by,
      :project_id,
      :visibility,
      :allowed_email_domains
    ])
    |> validate_required([:name, :description, :project_id])
  end

  def authorize(:create_request, _user), do: :ok

  # Admins can do anything
  def authorize(action, %{roles: :admin} = _user, _project)
      when action in [:update_request, :delete_request],
      do: :ok

  # Users can manage their own request
  def authorize(
        action,
        %{id: user_id} = _user,
        %{inserted_by: owner} = _project
      )
      when action in [:update_request, :delete_request] do
    user_id == owner
  end

  # Otherwise, denied
  def authorize(_, _, _), do: :error
end

defmodule Ingest.Requests.RequestSearch do
  @moduledoc """
  Reflects the virtual table for FTS5 trigram searching.
  """
  use Ecto.Schema

  @primary_key false
  schema "requests_search" do
    field :rowid, :integer
    field :id, :binary_id
    field :name, :string
    field :description, :string
    field :rank, :float, virtual: true
  end
end
