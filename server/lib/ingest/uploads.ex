defmodule Ingest.Uploads do
  @moduledoc """
  The Uploads context.
  """

  import Ecto.Query, warn: false
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
    Repo.all(from u in Upload, where: u.uploaded_by == ^user.id, limit: 10)
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
  def get_upload!(id), do: Repo.get!(Upload, id)

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
end
