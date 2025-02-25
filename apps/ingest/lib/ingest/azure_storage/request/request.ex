defmodule Datum.AzureStorage.Request do
  @moduledoc """
  Request is the base request module that the other requests use to do things like build
  authorization headers etc.
  """
  defmacro __using__(_opts) do
    quote do
      alias Datum.AzureStorage.Config

      def sign(%Req.Request{} = req, %Config{} = config, opts \\ []) do
        date = Keyword.get(opts, :date, DateTime.utc_now())
        path = req.url |> Map.get(:path, "/")

        resource = [
          "/",
          config.account_name,
          path
        ]

        # update with the standard headers
        req =
          req
          |> Req.Request.put_headers([
            # should we allow dynamic versioning? Probably not for now
            {"x-ms-version", "2023-11-03"},
            {"x-ms-date", date |> Calendar.strftime("%a, %d %b %Y %H:%M:%S GMT")}
          ])

        signature =
          [
            # HTTP Verb
            Atom.to_string(req.method) |> String.upcase(),
            # Content-Encoding
            "",
            # Content-Language
            "",
            # Content-Length
            if req.body do
              byte_size(req.body)
            else
              ""
            end,
            # Content-MD5
            "",
            # Content-Type
            content_type(req),
            # Date
            "",
            # If-Modified-Since
            "",
            # If-Match
            "",
            # If-None-Match,
            "",
            # If-Unmodified-Since
            "",
            # Range
            "",
            # CanoncicalizedHeader
            headers(req),
            # CanoncalizedResource
            resource | params(req)
          ]
          |> Enum.join("\n")

        signature =
          :crypto.mac(:hmac, :sha256, Base.decode64!(config.account_key), signature)
          |> Base.encode64()

        req
        |> Req.Request.put_header(
          "Authorization",
          "SharedKey #{config.account_name}:#{signature}"
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
        "#{if config.ssl do
          "https://"
        else
          "http://"
        end}#{config.base_service_url}"
      end
    end
  end
end
