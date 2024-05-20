defmodule Ingest.Uploads.Metadata do
  @moduledoc """
  This represents the metadata captured for a given upload. Typically the data itself is stored
  in the map and then written as a .json file to the storage medium.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ingest.Requests.Template
  alias Ingest.Uploads.Upload

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "metadata" do
    field :data, :map
    field :submitted, :boolean, default: false

    belongs_to :upload, Upload, type: :binary_id, foreign_key: :upload_id
    belongs_to :template, Template, type: :binary_id, foreign_key: :template_id

    timestamps()
  end

  @doc false
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [:submitted, :data, :upload_id, :template_id])
    |> validate_required([:upload_id, :template_id])
  end
end
