defmodule Ingest.Uploads.Upload do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "uploads" do
    field :size, :integer
    field :filename, :string
    field :ext, :string
    field :uploaded_by, :binary_id
    field :request_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :ext, :size])
    |> validate_required([:filename, :ext, :size])
  end
end
