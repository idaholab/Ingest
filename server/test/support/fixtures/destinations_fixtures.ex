defmodule Ingest.DestinationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ingest.Destinations` context.
  """

  @doc """
  Generate a client.
  """
  def client_fixture(attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Ingest.Destinations.create_client()

    client
  end
end
