defmodule AzureStorageTest do
  use ExUnit.Case
  doctest AzureStorage
  alias AzureStorage.Container
  alias AzureStorage.Blob

  defp azurite_config do
    %AzureStorage.Config{
      account_name: "devstoreaccount1",
      account_key:
        "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==",
      ssl: false,
      base_service_url: "127.0.0.1:10000/devstoreaccount1"
    }
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
end
