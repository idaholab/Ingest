defmodule Ingest.AccessFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ingest.Access` context.
  """

  @doc """
  Generate a policy.
  """
  def policy_fixture(attrs \\ %{}) do
    {:ok, policy} =
      attrs
      |> Enum.into(%{
        actions: [:create, :read],
        attributes: [],
        matcher: :match_one,
        name: "some name",
        resource_types: [Ingest.Access.Policy],
        scope: :global
      })
      |> Ingest.Access.create_policy()

    policy
  end

  @doc """
  Generate a resource_policy.
  """
  def resource_policy_fixture(attrs \\ %{}) do
    {:ok, resource_policy} =
      attrs
      |> Enum.into(%{
        resource_id: "7488a646-e31f-11e4-aace-600308960662",
        resource_type: "some resource_type"
      })
      |> Ingest.Access.create_resource_policy()

    resource_policy
  end
end
