defmodule Ingest.Requests.RequestMembers do
  @moduledoc """
  request members that have been invited based on request id and email.
  """
  alias Ingest.Requests.Request
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "request_members" do
    field(:email, :string)
    belongs_to(:request, Request, type: :binary_id, foreign_key: :request_id)

    timestamps()
  end

  @doc false
  def email_changeset(request_members, attrs) do
    request_members
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end
end
