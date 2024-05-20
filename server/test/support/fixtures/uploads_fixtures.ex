defmodule Ingest.UploadsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ingest.Uploads` context.
  """

  @doc """
  Generate a upload.
  """
  def upload_fixture(attrs \\ %{}) do
    {:ok, upload} =
      attrs
      |> Enum.into(%{
        ext: "some ext",
        filename: "some filename",
        size: 42
      })
      |> Ingest.Uploads.create_upload()

    upload
  end

  @doc """
  Generate a metadata.
  """
  def metadata_fixture(attrs \\ %{}) do
    {:ok, metadata} =
      attrs
      |> Enum.into(%{
        data: %{},
        uploaded: true
      })
      |> Ingest.Uploads.create_metadata()

    metadata
  end
end
