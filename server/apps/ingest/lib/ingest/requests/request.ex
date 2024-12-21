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

defmodule Ingest.Requests.RequestTemplates do
  @moduledoc """
  This structure allows us to add more data to the join of templates to
  their requests if needed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "request_templates" do
    belongs_to :request, Ingest.Requests.Request, foreign_key: :request_id, type: :binary_id
    belongs_to :template, Ingest.Requests.Template, foreign_key: :template_id, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(request_template, attrs) do
    request_template
    |> cast(attrs, [:request_id, :template_id])
    |> validate_required([:request_id, :template_id])
  end
end

defmodule Ingest.Requests.RequestDestination do
  @moduledoc """
  This structure allows us to add more data to the join of destinations to
  their requests if needed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "request_templates" do
    belongs_to :request, Ingest.Requests.Request, foreign_key: :request_id, type: :binary_id

    belongs_to :destination, Ingest.Destinations.Destination,
      foreign_key: :destination_id,
      type: :binary_id

    # this field can be any of the additional configurations per type, found
    # in the destination schema file itself. It relies on the destination type
    # to know what additional config to choose
    field :additional_config, :map

    timestamps()
  end

  @doc false
  def changeset(request_destination, attrs) do
    request_destination
    |> cast(attrs, [:request_id, :destination_id])
    |> validate_required([:request_id, :destination_id])
  end
end
