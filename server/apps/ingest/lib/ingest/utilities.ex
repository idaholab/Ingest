defmodule Ingest.Utilities do
  @doc """
  Function to set standard :httpc opts for working in the internal INL network, or behind any other proxy
  that would require a CA file
  """
  def httpc_opts() do
    case Mix.env() do
      :dev ->
        ssl_opts =
          :httpc.ssl_verify_host_options(true)
          |> Keyword.put(:cacertfile, Application.get_env(:ingest, :ca_certfile_path))
          |> Keyword.drop([:cacerts])

        %{ssl: ssl_opts}

      _ ->
        nil
    end
  end
end
