defmodule Ingest.Destinations.DestinationMembers do
  @moduledoc """
  The structure for managing destination members.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "destination_members" do
    field :role, Ecto.Enum, values: [:manager, :uploader]
    field :pending, :boolean, default: true

    belongs_to :destination, Ingest.Destinations.Destination,
      foreign_key: :destination_id,
      type: :binary_id

    belongs_to :user, Ingest.Accounts.User, foreign_key: :user_id, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(template_members, attrs) do
    template_members
    |> cast(attrs, [:role, :destination_id, :user_id, :pending])
    |> validate_required([:role, :destination_id])
  end
end
