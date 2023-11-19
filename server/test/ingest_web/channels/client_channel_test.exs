defmodule IngestWeb.ClientChannelTest do
  use IngestWeb.ChannelCase
  import Ingest.DestinationsFixtures

  setup do
    client = client_fixture()

    {:ok, reply, socket} =
      IngestWeb.UserSocket
      |> socket("user_id", %{current_user: client.owner_id, client_id: client.id})
      |> subscribe_and_join(IngestWeb.ClientChannel, "client:#{client.id}")

    %{socket: socket}
  end

  test "dir_update updates the cached entry", %{socket: socket} do
    ref = push(socket, "dir_update", %{"directories" => [%{"~/" => %{"test.pdf" => "57"}}]})
    assert_reply ref, :ok

    {:ok, results} = Cachex.get(:clients, "dir:#{socket.assigns.client_id}")
    assert match?([%{"~/" => %{"test.pdf" => "57"}}], results)
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to client:lobby", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end
end
