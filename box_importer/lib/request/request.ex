defmodule BoxImporter.Request do
  @moduledoc """
  Request is the base request module that the other requests use to do things like build
  authorization headers etc.
  """
  defmacro __using__(_opts) do
    quote do
      alias BoxImporter.Config

      def sign(%Req.Request{} = req, %Config{} = config, opts \\ []) do
        req
        |> Req.Request.put_header(
          "Authorization",
          "Bearer #{config.access_token}"
        )
      end

      defp headers(%Req.Request{} = req) do
        req.headers
        |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
        |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "x-ms-") end)
        |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)
        |> Enum.sort_by(fn {k, _v} -> k end)
        |> Enum.map(fn {k, v} ->
          v = v |> Enum.sort() |> Enum.join(",")
          "#{k}:#{v}"
        end)
        |> Enum.join("\n")
      end

      defp params(req) do
        if req.url.query do
          URI.decode_query(req.url.query)
          |> Enum.sort()
          |> Enum.map(fn {k, v} ->
            [to_string(k), ":", to_string(v)]
          end)
        else
          []
        end
      end

      defp content_type(%Req.Request{} = req) do
        content_type = req |> Req.Request.get_header("content-type")

        if content_type == [] do
          ""
        else
          hd(content_type)
        end
      end

      defp build_base_url(%Config{} = config) do
        {config.base_service_url}
      end
    end
  end
end
