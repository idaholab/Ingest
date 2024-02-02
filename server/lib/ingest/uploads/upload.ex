defmodule Ingest.Uploads.Upload do
  alias Ingest.Accounts.User
  alias Ingest.Requests.Request
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "uploads" do
    field :size, :integer
    field :filename, :string
    field :ext, :string

    belongs_to :request, Request, type: :binary_id
    belongs_to :user, User, type: :binary_id, foreign_key: :uploaded_by

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :ext, :size])
    |> validate_required([:filename])
  end
end
