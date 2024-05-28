defmodule BoxImporter.File do
  alias BoxImporter.Request
  alias BoxImporter.Config
  alias __MODULE__

  use BoxImporter.Request

  def new() do
  end

  def get_file(%Config{} = config, file_id) do
    {_request, response} =
      Req.Request.new(
        method: :get,
        url: "#{build_base_url(config)}/files/#{file_id}/content}"
      )
      |> sign(config)
      |> Req.Request.run_request()

    case response.status do
      %{status: 200, body: body} ->
        dbg(body)
        {:ok, "Downloaded successfully"}

      _ ->
        {:error, "Failed to download file"}
    end
  end
end
