defmodule Ingest.Destinations do
  @moduledoc """
  The Destinations context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Destinations.AzureConfig
  alias Ingest.Destinations.S3Config
  alias Ingest.Repo

  alias Ingest.Destinations.Client
  alias Ingest.Accounts.User

  @doc """
  Returns the list of clients.

  ## Examples

      iex> list_clients()
      [%Client{}, ...]

  """
  def list_clients do
    Repo.all(Client)
  end

  @doc """
  Gets a single client.

  Raises `Ecto.NoResultsError` if the Client does not exist.

  ## Examples

      iex> get_client!(123)
      %Client{}

      iex> get_client!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client!(id), do: Repo.get!(Client, id)

  def get_client_for_user(client_id, user_id) do
    Repo.get_by(Client, id: client_id, owner_id: user_id)
  end

  @doc """
  Creates a client.

  ## Examples

      iex> create_client(%{field: value})
      {:ok, %Client{}}

      iex> create_client(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_client(attrs \\ %{}) do
    %Client{}
    |> Client.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a client.

  ## Examples

      iex> update_client(client, %{field: new_value})
      {:ok, %Client{}}

      iex> update_client(client, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client(%Client{} = client, attrs) do
    client
    |> Client.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a client.

  ## Examples

      iex> delete_client(client)
      {:ok, %Client{}}

      iex> delete_client(client)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client(%Client{} = client) do
    Repo.delete(client)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client changes.

  ## Examples

      iex> change_client(client)
      %Ecto.Changeset{data: %Client{}}

  """
  def change_client(%Client{} = client, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  alias Ingest.Destinations.Destination

  @doc """
  Returns the list of destinations.

  ## Examples

      iex> list_destinations()
      [%Destination{}, ...]

  """
  def list_destinations do
    Repo.all(Destination)
  end

  def list_own_destinations(%User{} = user) do
    Repo.all(from d in Destination, where: d.inserted_by == ^user.id)
  end

  @doc """
  Gets a single destination.

  Raises `Ecto.NoResultsError` if the Destination does not exist.

  ## Examples

      iex> get_destination!(123)
      %Destination{}

      iex> get_destination!(456)
      ** (Ecto.NoResultsError)

  """
  def get_destination!(id) do
    destination = Repo.get!(Destination, id)

    case destination.type do
      :s3 ->
        %{
          destination
          | s3_config: %{destination.s3_config | access_key_id: nil, secret_access_key: nil}
        }

      :azure ->
        %{
          destination
          | azure_config: %{destination.azure_config | account_name: nil, account_key: nil}
        }

      :lakefs ->
        %{
          destination
          | lakefs_config: %{
              destination.lakefs_config
              | access_key_id: nil,
                secret_access_key: nil
            }
        }

      _ ->
        destination
    end
  end

  def get_destination(id) do
    Repo.get(Destination, id)
  end

  @doc """
  Creates a destination.

  ## Examples

      iex> create_destination(%{field: value})
      {:ok, %Destination{}}

      iex> create_destination(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_destination(attrs \\ %{}) do
    %Destination{}
    |> Destination.changeset(attrs)
    |> Repo.insert()
  end

  def create_destination_for_user(%User{} = user, attrs \\ %{}) do
    %Destination{}
    |> Destination.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a destination.

  ## Examples

      iex> update_destination(destination, %{field: new_value})
      {:ok, %Destination{}}

      iex> update_destination(destination, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_destination(%Destination{} = destination, attrs) do
    destination
    |> Destination.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a destination.

  ## Examples

      iex> delete_destination(destination)
      {:ok, %Destination{}}

      iex> delete_destination(destination)
      {:error, %Ecto.Changeset{}}

  """
  def delete_destination(%Destination{} = destination) do
    Repo.delete(destination)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking destination changes.

  ## Examples

      iex> change_destination(destination)
      %Ecto.Changeset{data: %Destination{}}

  """
  def change_destination(%Destination{} = destination, attrs \\ %{}) do
    Destination.changeset(destination, attrs)
  end

  def display_destination(%Destination{} = destination, attrs \\ %{}) do
    Destination.display_changeset(destination, attrs)
  end

  def change_s3_config(%S3Config{} = s3_config, attrs \\ %{}) do
    S3Config.changeset(s3_config, attrs)
  end

  def change_azure_config(%S3Config{} = azure_config, attrs \\ %{}) do
    AzureConfig.changeset(azure_config, attrs)
  end

  @defaults %{exclude: []}
  def search(search_term, opts \\ []) do
    %{exclude: exclude} = Enum.into(opts, @defaults)

    query =
      from(d in Destination,
        where:
          fragment(
            "searchable @@ websearch_to_tsquery(?)",
            ^search_term
          ) and d.id not in ^Enum.map(exclude, fn d -> d.id end),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(searchable, websearch_to_tsquery(?), 4)",
            ^search_term
          )
        }
      )

    Repo.all(query)
  end
end
