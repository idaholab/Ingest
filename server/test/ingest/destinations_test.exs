defmodule Ingest.DestinationsTest do
  use Ingest.DataCase

  alias Ingest.Destinations

  describe "clients" do
    alias Ingest.Destinations.Client

    import Ingest.DestinationsFixtures

    @invalid_attrs %{name: nil}

    test "list_clients/0 returns all clients" do
      client = client_fixture()
      assert Destinations.list_clients() == [client]
    end

    test "get_client!/1 returns the client with given id" do
      client = client_fixture()
      assert Destinations.get_client!(client.id) == client
    end

    test "create_client/1 with valid data creates a client" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Client{} = client} = Destinations.create_client(valid_attrs)
      assert client.name == "some name"
    end

    test "create_client/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Destinations.create_client(@invalid_attrs)
    end

    test "update_client/2 with valid data updates the client" do
      client = client_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Client{} = client} = Destinations.update_client(client, update_attrs)
      assert client.name == "some updated name"
    end

    test "update_client/2 with invalid data returns error changeset" do
      client = client_fixture()
      assert {:error, %Ecto.Changeset{}} = Destinations.update_client(client, @invalid_attrs)
      assert client == Destinations.get_client!(client.id)
    end

    test "delete_client/1 deletes the client" do
      client = client_fixture()
      assert {:ok, %Client{}} = Destinations.delete_client(client)
      assert_raise Ecto.NoResultsError, fn -> Destinations.get_client!(client.id) end
    end

    test "change_client/1 returns a client changeset" do
      client = client_fixture()
      assert %Ecto.Changeset{} = Destinations.change_client(client)
    end
  end
end
