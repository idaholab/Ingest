defmodule Ingest.Access do
  @moduledoc """
  The Access context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Repo

  alias Ingest.Access.Policy

  @list_policies_defaults %{
    scopes: [:global],
    actions: [:create, :read, :update, :list, :delete]
  }

  @doc """
  Returns the list of policies.

  ## Examples

      iex> list_policies()
      [%Policy{}, ...]

  """
  def list_policies do
    Repo.all(Policy)
  end

  @doc """
  Returns a list of policies matching the provided schemas and actions
  """
  def list_policies(schemas, opts \\ []) do
    %{scopes: scopes, actions: actions} = Enum.into(opts, @list_policies_defaults)

    action_query =
      Enum.reduce(actions, Policy, fn action, query ->
        query
        |> where([p], ^action in p.actions)
      end)

    where =
      Enum.reduce(schemas, action_query, fn schema, query ->
        schema = schema |> to_string

        query
        |> where([p], ^schema in p.resource_types)
      end)

    where
    |> where([p], p.scope in ^scopes)
    |> preload(:resource_policies)
    |> Repo.all()
  end

  @doc """
  Gets a single policy.

  Raises `Ecto.NoResultsError` if the Policy does not exist.

  ## Examples

      iex> get_policy!(123)
      %Policy{}

      iex> get_policy!(456)
      ** (Ecto.NoResultsError)

  """
  def get_policy!(id), do: Repo.get!(Policy, id)

  @doc """
  Creates a policy.

  ## Examples

      iex> create_policy(%{field: value})
      {:ok, %Policy{}}

      iex> create_policy(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_policy(attrs \\ %{}) do
    %Policy{}
    |> Policy.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a policy.

  ## Examples

      iex> update_policy(policy, %{field: new_value})
      {:ok, %Policy{}}

      iex> update_policy(policy, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_policy(%Policy{} = policy, attrs) do
    policy
    |> Policy.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a policy.

  ## Examples

      iex> delete_policy(policy)
      {:ok, %Policy{}}

      iex> delete_policy(policy)
      {:error, %Ecto.Changeset{}}

  """
  def delete_policy(%Policy{} = policy) do
    Repo.delete(policy)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking policy changes.

  ## Examples

      iex> change_policy(policy)
      %Ecto.Changeset{data: %Policy{}}

  """
  def change_policy(%Policy{} = policy, attrs \\ %{}) do
    Policy.changeset(policy, attrs)
  end

  alias Ingest.Access.ResourcePolicy

  @doc """
  Returns the list of resource_policies.

  ## Examples

      iex> list_resource_policies()
      [%ResourcePolicy{}, ...]

  """
  def list_resource_policies do
    Repo.all(ResourcePolicy)
  end

  @doc """
  Gets a single resource_policy.

  Raises `Ecto.NoResultsError` if the Resource policy does not exist.

  ## Examples

      iex> get_resource_policy!(123)
      %ResourcePolicy{}

      iex> get_resource_policy!(456)
      ** (Ecto.NoResultsError)

  """
  def get_resource_policy!(id), do: Repo.get!(ResourcePolicy, id)

  @doc """
  Creates a resource_policy.

  ## Examples

      iex> create_resource_policy(%{field: value})
      {:ok, %ResourcePolicy{}}

      iex> create_resource_policy(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource_policy(attrs \\ %{}) do
    %ResourcePolicy{}
    |> ResourcePolicy.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource_policy.

  ## Examples

      iex> update_resource_policy(resource_policy, %{field: new_value})
      {:ok, %ResourcePolicy{}}

      iex> update_resource_policy(resource_policy, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource_policy(%ResourcePolicy{} = resource_policy, attrs) do
    resource_policy
    |> ResourcePolicy.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource_policy.

  ## Examples

      iex> delete_resource_policy(resource_policy)
      {:ok, %ResourcePolicy{}}

      iex> delete_resource_policy(resource_policy)
      {:error, %Ecto.Changeset{}}

  """
  def delete_resource_policy(%ResourcePolicy{} = resource_policy) do
    Repo.delete(resource_policy)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource_policy changes.

  ## Examples

      iex> change_resource_policy(resource_policy)
      %Ecto.Changeset{data: %ResourcePolicy{}}

  """
  def change_resource_policy(%ResourcePolicy{} = resource_policy, attrs \\ %{}) do
    ResourcePolicy.changeset(resource_policy, attrs)
  end
end
