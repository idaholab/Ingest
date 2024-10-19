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

  describe "destinations" do
    alias Ingest.Destinations.Destination

    import Ingest.DestinationsFixtures

    @invalid_attrs %{name: nil, type: nil, config: nil}

    test "list_destinations/0 returns all destinations" do
      destination = destination_fixture()
      assert Destinations.list_destinations() |> Enum.member?(destination)
    end

    test "get_destination!/1 returns the destination with given id" do
      destination = destination_fixture()
      assert Destinations.get_destination!(destination.id) == destination
    end

    test "create_destination/1 with valid data creates a destination" do
      valid_attrs = %{name: "some name", type: :temporary}

      assert {:ok, %Destination{} = destination} = Destinations.create_destination(valid_attrs)
      assert destination.name == "some name"
      assert destination.type == :temporary
    end

    test "create_destination/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Destinations.create_destination(@invalid_attrs)
    end

    test "update_destination/2 with valid data updates the destination" do
      destination = destination_fixture()
      update_attrs = %{name: "some updated name", type: :temporary}

      assert {:ok, %Destination{} = destination} =
               Destinations.update_destination(destination, update_attrs)

      assert destination.name == "some updated name"
      assert destination.type == :temporary
    end

    test "update_destination/2 with invalid data returns error changeset" do
      destination = destination_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Destinations.update_destination(destination, @invalid_attrs)

      assert destination == Destinations.get_destination!(destination.id)
    end

    test "delete_destination/1 deletes the destination" do
      destination = destination_fixture()
      assert {:ok, %Destination{}} = Destinations.delete_destination(destination)
      assert_raise Ecto.NoResultsError, fn -> Destinations.get_destination!(destination.id) end
    end

    test "change_destination/1 returns a destination changeset" do
      destination = destination_fixture()
      assert %Ecto.Changeset{} = Destinations.change_destination(destination)
    end
  end
end
