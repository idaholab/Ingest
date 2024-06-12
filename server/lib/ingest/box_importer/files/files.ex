defmodule BoxImporter.Files do
  alias BoxImporter.Request
  alias BoxImporter.Config
  alias __MODULE__
  alias File

  use BoxImporter.Request

  alias Ingest.Uploaders

  def new() do
  end

  # If Lakefs / Azure / S3 Destinations
  def get_file(%Config{} = config, destinationConfig, type, file_id) do
    {_request, response} =
      Req.Request.new(
        method: :get,
        url: "https://api.box.com/2.0/files/#{file_id}/content",
        options: [
          connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
        ]
      )
      |> sign(config)
      |> Req.Request.run_request()

    file_url = response.headers["location"] |> List.first()

    {_request, response} =
      Req.Request.new(
        method: :get,
        url: "https://api.box.com/2.0/files/#{file_id}/",
        options: [
          connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
        ]
      )
      |> sign(config)
      |> Req.Request.run_request()

    file_name = response.body["name"]

    if type == "azure" do
      {:ok, pid} = AzureStorage.start_link(destinationConfig)
      {:ok, container} = AzureStorage.new_container(pid, destinationConfig.container)
      {:ok, blob} = AzureStorage.new_blob(pid, container, file_name)

      list_of_blocks = []

      {_request, response} =
        Req.Request.new(
          method: :get,
          url: file_url,
          options: [
            connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
          ],
          into: fn {:data, data}, {req, resp} ->
            {:ok, block_id} =
              pid |> AzureStorage.put_block(blob, data)

            list_of_blocks = [block_id | list_of_blocks]

            {:cont, {req, resp}}
          end
        )
        |> Req.Request.run_request()

      {:ok, _nil} =
        pid |> AzureStorage.commit_blocklist(blob, list_of_blocks)
    end

    if type == "s3" do

      {:ok, state} = S3.init(destinationConfig, file_name, state)

      {_request, response} =
        Req.Request.new(
          method: :get,
          url: file_url,
          options: [
            connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
          ],
          into: fn {:data, data}, {req, resp} ->
            {:ok, new_state} = S3.upload_chunk(destinationConfig, file_name, state, data)

            {:cont, {req, resp}}
          end
        )
        |> Req.Request.run_request()

      {:ok, location} = S3.commit(destinationConfig, file_name, state)

    end

    if type == "lakefs" do
      {:ok, state} = Lakefs.init(destinationConfig, file_name, state)

      {_request, response} =
        Req.Request.new(
          method: :get,
          url: file_url,
          options: [
            connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
          ],
          into: fn {:data, data}, {req, resp} ->
            {:ok, new_state} = Lakefs.upload_chunk(destinationConfig, file_name, state, data)

            {:cont, {req, resp}}
          end
        )
        |> Req.Request.run_request()

      {:ok, location} = Lakefs.commit(destinationConfig, file_name, state)

    end
  end
end
