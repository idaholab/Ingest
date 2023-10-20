defmodule Ingest.Access do
  @moduledoc """
  The Access context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Repo

  alias Ingest.Access.Policy

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
  def list_policies(schemas, actions) do
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
end
