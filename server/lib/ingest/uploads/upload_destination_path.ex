defmodule Ingest.Uploads.UploadDestinationPath do
  @moduledoc """
  This represents a join table for the uploads to destinations so we can record the path/key
  for each given destination so as to avoid any issues
  """
  alias Ingest.Destinations.Destination
  alias Ingest.Uploads.Upload
  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type :binary_id
  @primary_key false
  schema "upload_destination_paths" do
    field :path, :string
    belongs_to :upload, Upload, type: :binary_id, foreign_key: :upload_id
    belongs_to :destination, Destination, type: :binary_id, foreign_key: :destination_id
  end

  @doc false
  def changeset(upload_destination_path, attrs) do
    upload_destination_path
    |> cast(attrs, [:path])
    |> validate_required([:path])
  end
end
