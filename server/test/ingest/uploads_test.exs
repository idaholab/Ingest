defmodule Ingest.UploadsTest do
  use Ingest.DataCase

  alias Ingest.Uploads

  describe "uploads" do
    alias Ingest.Uploads.Upload

    import Ingest.UploadsFixtures

    @invalid_attrs %{size: nil, filename: nil, ext: nil}

    test "list_uploads/0 returns all uploads" do
      upload = upload_fixture()
      assert Uploads.list_uploads() == [upload]
    end

    test "get_upload!/1 returns the upload with given id" do
      upload = upload_fixture()
      assert Uploads.get_upload!(upload.id) == upload
    end

    test "create_upload/1 with valid data creates a upload" do
      valid_attrs = %{size: 42, filename: "some filename", ext: "some ext"}

      assert {:ok, %Upload{} = upload} = Uploads.create_upload(valid_attrs)
      assert upload.size == 42
      assert upload.filename == "some filename"
      assert upload.ext == "some ext"
    end

    test "create_upload/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Uploads.create_upload(@invalid_attrs)
    end

    test "update_upload/2 with valid data updates the upload" do
      upload = upload_fixture()
      update_attrs = %{size: 43, filename: "some updated filename", ext: "some updated ext"}

      assert {:ok, %Upload{} = upload} = Uploads.update_upload(upload, update_attrs)
      assert upload.size == 43
      assert upload.filename == "some updated filename"
      assert upload.ext == "some updated ext"
    end

    test "update_upload/2 with invalid data returns error changeset" do
      upload = upload_fixture()
      assert {:error, %Ecto.Changeset{}} = Uploads.update_upload(upload, @invalid_attrs)
      assert upload == Uploads.get_upload!(upload.id)
    end

    test "delete_upload/1 deletes the upload" do
      upload = upload_fixture()
      assert {:ok, %Upload{}} = Uploads.delete_upload(upload)
      assert_raise Ecto.NoResultsError, fn -> Uploads.get_upload!(upload.id) end
    end

    test "change_upload/1 returns a upload changeset" do
      upload = upload_fixture()
      assert %Ecto.Changeset{} = Uploads.change_upload(upload)
    end
  end

  describe "metadata" do
    alias Ingest.Uploads.Metadata

    import Ingest.UploadsFixtures

    @invalid_attrs %{data: nil, uploaded: nil}

    test "list_metadata/0 returns all metadata" do
      metadata = metadata_fixture()
      assert Uploads.list_metadata() == [metadata]
    end

    test "get_metadata!/1 returns the metadata with given id" do
      metadata = metadata_fixture()
      assert Uploads.get_metadata!(metadata.id) == metadata
    end

    test "create_metadata/1 with valid data creates a metadata" do
      valid_attrs = %{data: %{}, uploaded: true}

      assert {:ok, %Metadata{} = metadata} = Uploads.create_metadata(valid_attrs)
      assert metadata.data == %{}
      assert metadata.uploaded == true
    end

    test "create_metadata/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Uploads.create_metadata(@invalid_attrs)
    end

    test "update_metadata/2 with valid data updates the metadata" do
      metadata = metadata_fixture()
      update_attrs = %{data: %{}, uploaded: false}

      assert {:ok, %Metadata{} = metadata} = Uploads.update_metadata(metadata, update_attrs)
      assert metadata.data == %{}
      assert metadata.uploaded == false
    end

    test "update_metadata/2 with invalid data returns error changeset" do
      metadata = metadata_fixture()
      assert {:error, %Ecto.Changeset{}} = Uploads.update_metadata(metadata, @invalid_attrs)
      assert metadata == Uploads.get_metadata!(metadata.id)
    end

    test "delete_metadata/1 deletes the metadata" do
      metadata = metadata_fixture()
      assert {:ok, %Metadata{}} = Uploads.delete_metadata(metadata)
      assert_raise Ecto.NoResultsError, fn -> Uploads.get_metadata!(metadata.id) end
    end

    test "change_metadata/1 returns a metadata changeset" do
      metadata = metadata_fixture()
      assert %Ecto.Changeset{} = Uploads.change_metadata(metadata)
    end
  end
end
