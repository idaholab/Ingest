defmodule BoxImporter.Files do
  alias BoxImporter.Request
  alias BoxImporter.Config
  alias __MODULE__
  alias File

  use BoxImporter.Request

  def new() do
  end

  def get_file(%Config{} = config, file_id) do
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

    dbg(config)

    file_url = response.headers["location"] |> List.first()

    {_request, response} =
      Req.Request.new(
        method: :get,
        url: file_url,
        options: [
          connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
        ]
      )
      |> Req.Request.run_request()

    content_disposition =
      response.headers["content-disposition"]
      |> List.first()

    pattern = ~r/filename\*=UTF-8''([\w%\-\.]+)(?:; ?|$)/i

    # Set default filename
    case Regex.run(pattern, content_disposition) do
      [_, filename] ->
        case response do
          %{status: 200} ->
            File.write("#{filename}", IO.iodata_to_binary(response.body))
            {:ok, filename}

          _ ->
            {:error, "Failed to download file"}
        end

      _ ->
        {:error, "Failed to get filename"}
    end
  end
end
