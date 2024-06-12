defmodule BoxImporter.Files do
  @moduledoc """
  File uploader
  """
  alias BoxImporter.Request
  alias BoxImporter.Config
  alias __MODULE__
  alias File

  use BoxImporter.Request

  alias Ingest.Uploaders.S3

  alias Ingest.Uploaders.Lakefs

  alias Ingest.Uploaders.Azure

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
      state = %{}
      state = Azure.init(destinationConfig, file_name, state)

      {_request, _response} =
        Req.Request.new(
          method: :get,
          url: file_url,
          options: [
            connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
          ],
          into: fn {:data, data}, {req, resp} ->
            {:ok, block_id} = Azure.upload_chunk(destinationConfig, file_name, state, data)

            Map.update!(state, :parts, fn parts -> [block_id | parts] end)

            {:cont, {req, resp}}
          end
        )
        |> Req.Request.run_request()

      {:ok, _location} = Azure.commit(destinationConfig, file_name, state)
    end

    if type == "s3" do
      state = %{}

      state = S3.init(destinationConfig, file_name, state)

      {_request, _response} =
        Req.Request.new(
          method: :get,
          url: file_url,
          options: [
            connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
          ],
          into: fn {:data, data}, {req, resp} ->
            {:ok, chunk_id} = S3.upload_chunk(destinationConfig, file_name, state, data)
            Map.update!(state, :parts, fn parts -> [chunk_id | parts] end)
            {:cont, {req, resp}}
          end
        )
        |> Req.Request.run_request()

      {:ok, _location} = S3.commit(destinationConfig, file_name, state)
    end

    if type == "lakefs" do
      state = %{}

      state = Lakefs.init(destinationConfig, file_name, state)

      {_request, _response} =
        Req.Request.new(
          method: :get,
          url: file_url,
          options: [
            connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
          ],
          into: fn {:data, data}, {req, resp} ->
            {:ok, chunk_id} = Lakefs.upload_chunk(destinationConfig, file_name, state, data)

            Map.update!(state, :parts, fn parts -> [chunk_id | parts] end)

            {:cont, {req, resp}}
          end
        )
        |> Req.Request.run_request()

      {:ok, _location} = Lakefs.commit(destinationConfig, file_name, state)
    end

    {:ok}
  end
end
