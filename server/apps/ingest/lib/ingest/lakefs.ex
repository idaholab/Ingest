defmodule Ingest.LakeFS do
  @moduledoc """
  All functions pertaining to communicating with LakeFS.
  """

  # note: do not use this function for massive files as it does not treat the response
  # as a stream - if you need a stream, you'll need to write it in as this is typically
  # used for getting the m.json files and those are going to be held in memory anyways
  def download_file(repo, ref, path) do
    config = Application.get_env(:ingest, :lakefs)
    url = config[:url]
    key = config[:access_key]
    secret = config[:secret_access_key]

    with %{status: 200, body: body} <-
           Req.get!("#{url}/api/v1/repositories/#{repo}/refs/#{ref}/objects",
             params: [path: path],
             auth: {:basic, "#{key}:#{secret}"}
           ) do
      {:ok, body}
    else
      err -> {:error, err}
    end
  end

  def presigned_download_url(url, repo, ref, path) do
    config = Application.get_env(:ingest, :lakefs)
    key = config[:access_key]
    secret = config[:secret_access_key]

    resp =
      Req.get!("#{url}/api/v1/repositories/#{repo}/refs/#{ref}/objects",
        params: [path: path, presign: true],
        auth: {:basic, "#{key}:#{secret}"},
        redirect: false
      )

    # we return the raw response struct here for ease of use
    {:ok, resp}
  end

  # this function pulls the metadata out of the object storage itself, as we are no longer storing
  # it as .m.json files but intead on the objects themselves
  def download_metadata(repo, ref, path) do
    config = Application.get_env(:ingest, :lakefs)
    url = config[:url]
    key = config[:access_key]
    secret = config[:secret_access_key]

    with %{status: 200, body: body} <-
           Req.get!("#{url}/api/v1/repositories/#{repo}/refs/#{ref}/objects/stat",
             params: [path: path],
             auth: {:basic, "#{key}:#{secret}"}
           ) do
      {:ok, body}
    else
      err -> {:error, err}
    end
  end

  # the diff merge function takes 3 functions, to be executed depending on whether or not
  # a file in the merge has been changed, removed, or created
  def diff_merge(
        %{
          "event_type" => "pre-merge",
          "source_ref" => source_ref,
          "branch_id" => "main",
          "repository_id" => repo
        } = _event,
        on_delete,
        on_update,
        on_create
      ) do
    config = Application.get_env(:ingest, :lakefs)
    url = config[:url]
    key = config[:access_key]
    secret = config[:secret_access_key]

    with %{status: 200, body: %{"results" => results} = _body} <-
           Req.get!("#{url}/api/v1/repositories/#{repo}/refs/main/diff/#{source_ref}",
             auth: {:basic, "#{key}:#{secret}"}
           ) do
      # Example of a result:
      # {"path" => "data01.csv", "path_type" => "object", "size_bytes" => 11, "type" => "changed"}
      {statuses, messages} =
        results
        |> Enum.map(fn result ->
          case result["type"] do
            "added" -> on_create.(repo, source_ref, result)
            "changed" -> on_update.(repo, source_ref, result)
            "removed" -> on_delete.(repo, source_ref, result)
          end
        end)
        |> Enum.unzip()

      if statuses |> Enum.member?(:error) do
        {:error, messages}
      else
        {:ok, messages}
      end
    else
      err -> {:error, err}
    end
  end
end
