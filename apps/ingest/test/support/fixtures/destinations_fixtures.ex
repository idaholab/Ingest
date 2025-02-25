defmodule Ingest.DestinationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ingest.Destinations` context.
  """
  alias Ecto.UUID
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a client.
  """
  def client_fixture(attrs \\ %{}) do
    {:ok, user} =
      Ingest.Accounts.register_user(%{
        email: unique_user_email(),
        password: "xxxxxxxxxxxx",
        name: "Administrator"
      })

    {:ok, client} =
      attrs
      |> Enum.into(%{
        id: UUID.generate(),
        name: "some name",
        token: "some token",
        owner_id: user.id
      })
      |> Ingest.Destinations.create_client()

    client
  end

  @doc """
  Generate a destination.
  """
  def destination_fixture(attrs \\ %{}) do
    {:ok, destination} =
      attrs
      |> Enum.into(%{
        config: %{},
        name: "some name",
        type: :temporary
      })
      |> Ingest.Destinations.create_destination()

    destination
  end
end
