defmodule Ingest.Destinations.Client do
  @moduledoc """
  This represents the Ingest Client application running on a user's machine. We keep track
  of the actual client, eventually some metadata about it, and the token we granted it.
  """
  alias Ingest.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  # autogenerate is false because the client_id is provided by the client itself
  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "clients" do
    field :name, :string
    # we will eventually want to pull this out into a table so that we can keep better
    # track of all tokens granted by our application, for now though, we need to at least
    # keep track of the token given to a client so that we can validate and revoke if needed
    field :token, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :owner_id

    timestamps()
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [:name, :owner_id])
    |> validate_required([:name, :owner_id])
  end
end
