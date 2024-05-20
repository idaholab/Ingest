defmodule Ingest.Uploads do
  @moduledoc """
  The Uploads context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Requests.Template
  alias Ingest.Uploads.Metadata
  alias Ingest.Requests.Request
  alias Ingest.Accounts.User
  alias Ingest.Repo

  alias Ingest.Uploads.Upload

  @doc """
  Returns the list of uploads.

  ## Examples

      iex> list_uploads()
      [%Upload{}, ...]

  """
  def list_uploads do
    Repo.all(Upload)
  end

  def recent_uploads_for_user(%User{} = user) do
    Repo.all(from u in Upload, where: u.uploaded_by == ^user.id, limit: 10, preload: :metadatas)
  end

  def uploads_missing_metadata(%User{} = user) do
    Repo.all(
      from u in Upload,
        left_join: m in Metadata,
        on: m.upload_id == u.id,
        where:
          (is_nil(m.id) and u.uploaded_by == ^user.id) or
            (u.uploaded_by == ^user.id and m.submitted == false),
        distinct: true,
        select: u
    )
  end

  def count_uploads_missing_metadata(%User{} = user) do
    Repo.one(
      from u in Upload,
        left_join: m in Metadata,
        on: m.upload_id == u.id,
        where:
          (is_nil(m.id) and u.uploaded_by == ^user.id) or
            (u.uploaded_by == ^user.id and m.submitted == false),
        select: count(u.id, :distinct)
    )
  end

  @doc """
  Gets a single upload.

  Raises `Ecto.NoResultsError` if the Upload does not exist.

  ## Examples

      iex> get_upload!(123)
      %Upload{}

      iex> get_upload!(456)
      ** (Ecto.NoResultsError)

  """
  def get_upload!(id),
    do:
      Repo.get!(Upload, id)
      |> Repo.preload(:user)
      |> Repo.preload(metadatas: from(m in Metadata, where: m.submitted == true))
      |> Repo.preload(request: [:destinations, project: :user])

  def get_upload(id),
    do:
      Repo.get(Upload, id)
      |> Repo.preload(:user)
      |> Repo.preload(metadatas: from(m in Metadata, where: m.submitted == true))
      |> Repo.preload(request: [:destinations, project: :user])

  @doc """
  Creates a upload.

  ## Examples

      iex> create_upload(%{field: value})
      {:ok, %Upload{}}

      iex> create_upload(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_upload(attrs \\ %{}, %Request{} = request, %User{} = user) do
    %Upload{}
    |> Upload.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:request, request)
    |> Repo.insert()
  end

  @doc """
  Updates a upload.

  ## Examples

      iex> update_upload(upload, %{field: new_value})
      {:ok, %Upload{}}

      iex> update_upload(upload, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_upload(%Upload{} = upload, attrs) do
    upload
    |> Upload.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a upload.

  ## Examples

      iex> delete_upload(upload)
      {:ok, %Upload{}}

      iex> delete_upload(upload)
      {:error, %Ecto.Changeset{}}

  """
  def delete_upload(%Upload{} = upload) do
    Repo.delete(upload)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking upload changes.

  ## Examples

      iex> change_upload(upload)
      %Ecto.Changeset{data: %Upload{}}

  """
  def change_upload(%Upload{} = upload, attrs \\ %{}) do
    Upload.changeset(upload, attrs)
  end

  alias Ingest.Uploads.Metadata

  @doc """
  Returns the list of metadata.

  ## Examples

      iex> list_metadata()
      [%Metadata{}, ...]

  """
  def list_metadata_by(%Upload{} = upload, %Template{} = template) do
    Repo.one(
      from m in Metadata,
        where: m.upload_id == ^upload.id and m.template_id == ^template.id,
        select: m
    )
  end

  def list_metadata(%Upload{} = upload) do
    Repo.all(
      from m in Metadata,
        where: m.upload_id == ^upload.id,
        select: m
    )
  end

  @doc """
  Gets a single metadata.

  Raises `Ecto.NoResultsError` if the Metadata does not exist.

  ## Examples

      iex> get_metadata!(123)
      %Metadata{}

      iex> get_metadata!(456)
      ** (Ecto.NoResultsError)

  """
  def get_metadata!(id), do: Repo.get!(Metadata, id)

  @doc """
  Creates a metadata.

  ## Examples

      iex> create_metadata(%{field: value})
      {:ok, %Metadata{}}

      iex> create_metadata(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_metadata(attrs \\ %{}) do
    %Metadata{}
    |> Metadata.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a metadata.

  ## Examples

      iex> update_metadata(metadata, %{field: new_value})
      {:ok, %Metadata{}}

      iex> update_metadata(metadata, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_metadata(%Metadata{} = metadata, attrs) do
    metadata
    |> Metadata.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a metadata.

  ## Examples

      iex> delete_metadata(metadata)
      {:ok, %Metadata{}}

      iex> delete_metadata(metadata)
      {:error, %Ecto.Changeset{}}

  """
  def delete_metadata(%Metadata{} = metadata) do
    Repo.delete(metadata)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking metadata changes.

  ## Examples

      iex> change_metadata(metadata)
      %Ecto.Changeset{data: %Metadata{}}

  """
  def change_metadata(%Metadata{} = metadata, attrs \\ %{}) do
    Metadata.changeset(metadata, attrs)
  end

  def uploads_for_request_count(%Request{} = request) do
    Repo.one!(from u in Upload, where: u.request_id == ^request.id, select: count())
  end
end
