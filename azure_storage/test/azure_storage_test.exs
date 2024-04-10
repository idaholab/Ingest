defmodule AzureStorageTest do
  use ExUnit.Case
  doctest AzureStorage
  alias AzureStorage.Container
  alias AzureStorage.Blob
  import Config

  defp azurite_config do
    %AzureStorage.Config{
      account_name: "devstoreaccount1",
      account_key:
        "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==",
      ssl: false,
      base_service_url: "127.0.0.1:10000/devstoreaccount1"
    }
  end

  describe "containers" do
    test "can list blobs in the container" do
      {:ok, nil} =
        Container.new("test")
        |> Container.list_blobs(azurite_config())
    end
  end

  describe "blobs" do
    test "can upload a simple blob" do
      {:ok, _blob} =
        Container.new("test")
        |> Blob.new("test")
        |> Blob.put_blob(azurite_config(), "testing data")
    end

    test "can upload a multiple blocks to a single blob" do
      {:ok, _block_id} =
        Container.new("test")
        |> Blob.new("blocktest")
        |> Blob.put_block(azurite_config(), "testing data")

      {:ok, _block_id} =
        Container.new("test")
        |> Blob.new("blocktest")
        |> Blob.put_block(azurite_config(), "second testing data")
    end

    test "can upload a multiple blocks to a single blob and commit them" do
      blob =
        Container.new("test")
        |> Blob.new("block commit test")

      {:ok, first} =
        blob
        |> Blob.put_block(azurite_config(), "testing data")

      {:ok, second} =
        blob
        |> Blob.put_block(azurite_config(), "second testing data")

      {:ok, _nil} = Blob.put_block_list([first, second], blob, azurite_config())
    end
  end

  describe "the provided genserver" do
    test "can upload a blob" do
      {:ok, pid} =
        AzureStorage.start_link(
          account_name: "devstoreaccount1",
          account_key:
            "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==",
          ssl: false,
          base_service_url: "127.0.0.1:10000/devstoreaccount1"
        )

      {:ok, container} = AzureStorage.new_container(pid, "test")

      {:ok, blob} =
        pid |> AzureStorage.put_blob(container, "genservertest.txt", "genserver testing")

      assert(blob.name == "genservertest.txt")
    end

    test "can upload a block and commit a blocklist" do
      {:ok, pid} =
        AzureStorage.start_link(
          account_name: "devstoreaccount1",
          account_key:
            "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==",
          ssl: false,
          base_service_url: "127.0.0.1:10000/devstoreaccount1"
        )

      {:ok, container} = AzureStorage.new_container(pid, "test")
      {:ok, blob} = AzureStorage.new_blob(pid, container, "blocklistcommittest.txt")

      {:ok, first_block_id} =
        pid |> AzureStorage.put_block(blob, "genserver block testing")

      {:ok, second_block_id} =
        pid |> AzureStorage.put_block(blob, "genserver block testing 2")

      {:ok, _nil} =
        pid |> AzureStorage.commit_blocklist(blob, [first_block_id, second_block_id])
    end
  end
end
