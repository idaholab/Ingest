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
        attributes: %{},
        matcher: :match_one,
        name: "some name",
        resource_types: ["option1", "option2"]
      })
      |> Ingest.Access.create_policy()

    policy
  end
end
