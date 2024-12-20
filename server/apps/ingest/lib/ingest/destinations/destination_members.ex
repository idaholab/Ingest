defmodule Ingest.Destinations.DestinationMembers do
  @moduledoc """
  The structure for managing destination members.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "destination_members" do
    field :email, :string
    field :role, Ecto.Enum, values: [:manager, :uploader]

    field :status, Ecto.Enum,
      values: [:accepted, :rejected, :pending, :not_requested],
      default: :not_requested

    # these fields are needed so that we can trace back if this was created by someone requesting
    # access for a particular project, request
    belongs_to :project, Ingest.Projects.Project, foreign_key: :project_id, type: :binary_id
    belongs_to :request, Ingest.Requests.Request, foreign_key: :request_id, type: :binary_id

    belongs_to :destination, Ingest.Destinations.Destination,
      foreign_key: :destination_id,
      type: :binary_id

    belongs_to :user, Ingest.Accounts.User, foreign_key: :user_id, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(template_members, attrs) do
    template_members
    |> cast(attrs, [:role, :destination_id, :user_id, :status, :email])
    |> validate_required([:role, :destination_id])
  end
end
