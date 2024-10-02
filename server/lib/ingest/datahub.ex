defmodule Ingest.DataHub do
  @moduledoc """
  DataHub contains all the functions for communicating with DataHub.
  """

  # look up pattern matching if you don't understand this pattern - it's almost
  # like function overloading, where we use an atom to specify which aspect we're
  # going to include on the dataset event
  def create_dataset_event(path, platform) do
    dataset_proposal(dataset_urn(path, platform),
      aspect_name: "datasetKey",
      aspect: %{
        name: dataset_urn(path, platform),
        platform: platform_urn(platform),
        origin: env()
      }
    )
  end

  def delete_dataset(path, platform) do
    payload = %{
      urn: dataset_urn(path, platform)
    }

    config = Application.get_env(:ingest, :datahub)

    token = config[:token]
    url = config[:gms_url]

    # so far this is the only method using these sets of endpoints so I didn't want to
    # make this fancy like the others
    resp =
      Req.post!("#{url}/entities?action=delete",
        json: payload,
        auth: {:bearer, token}
      )

    case resp do
      %{status: 200} -> {:ok, :deleted}
      _ -> {:error, resp.body}
    end
  end

  def create_dataset_event(:properties, path, platform, opts) do
    custom = Keyword.fetch!(opts, :custom)
    name = Keyword.get(opts, :name)
    description = Keyword.get(opts, :description, "")

    dataset_proposal(dataset_urn(path, platform),
      aspect_name: "datasetProperties",
      aspect: properties_aspect(name, description, custom)
    )
  end

  def create_dataset_event(:owners, path, platform, opts) do
    owners = Keyword.fetch!(opts, :owners)
    type = Keyword.get(opts, :owner_type, "DATA_STEWARD")

    dataset_proposal(dataset_urn(path, platform),
      aspect_name: "ownership",
      aspect: %{owners: Enum.map(owners, fn owner -> ownership_aspect(owner, type) end)}
    )
  end

  def create_dataset_event(:tags, path, platform, opts) do
    tags = Keyword.fetch!(opts, :tags)

    dataset_proposal(dataset_urn(path, platform),
      aspect_name: "globalTags",
      aspect: %{tags: Enum.map(tags, fn t -> %{tag: tag_urn(t)} end)}
    )
  end

  def create_dataset_event(:project, path, platform, opts) do
    name = Keyword.fetch!(opts, :name)
    description = Keyword.get(opts, :description, "")

    dataset_proposal(dataset_urn(path, platform),
      aspect_name: "project",
      aspect: %{name: name, description: description}
    )
  end

  def create_dataset_event(:download_link, path, platform, opts) do
    repo = Keyword.fetch!(opts, :repo)
    branch = Keyword.fetch!(opts, :branch)
    filename = Keyword.fetch!(opts, :filename)
    endpoint = Keyword.fetch!(opts, :endpoint)
    email = Keyword.get(opts, :email, "alexandria@inl.gov")

    dataset_proposal(dataset_urn(path, platform),
      aspect_name: "downloadLink",
      aspect: %{
        repo: repo,
        branch: branch,
        filename: filename,
        endpoint: endpoint,
        contact_email: email
      }
    )
  end

  def create_tag_event(name) do
    %{
      proposal: %{
        entityUrn: tag_urn(name),
        entityType: "tag",
        aspectName: "tagKey",
        changeType: "UPSERT",
        aspect: %{
          contentType: "application/json",
          value:
            Jason.encode!(%{
              name: name
            })
        }
      }
    }
  end

  def send_event(event) do
    config = Application.get_env(:ingest, :datahub)

    token = config[:token]
    url = config[:gms_url]

    resp =
      Req.post!("#{url}/aspects?action=ingestProposal",
        json: event,
        auth: {:bearer, token}
      )

    case resp do
      %{status: 200} -> {:ok, :created}
      %{status: 201} -> {:ok, :created}
      %{status: 202} -> {:ok, :updated}
      _ -> {:error, resp.body}
    end
  end

  def get_download_link(urn, opts \\ []) do
    config = Application.get_env(:ingest, :datahub)

    token = Keyword.get(opts, :token, config[:token])
    url = Keyword.get(opts, :url, config[:url])

    resp =
      Req.get!(
        "#{url}/openapi/v3/entity/dataset/#{urn}?systemMetadata=false&aspects=downloadLink",
        auth: {:bearer, token}
      )

    case resp.status do
      200 -> {:ok, resp.body["downloadLink"]["value"]}
      _ -> {:error, resp.body}
    end
  end

  defp properties_aspect(name, description, custom) when is_map(custom) do
    %{name: name, description: description, customProperties: custom}
  end

  defp ownership_aspect(name, type) do
    %{owner: user_urn(name), type: String.upcase(type)}
  end

  def tag_aspect(name) do
    %{tag: tag_urn(name)}
  end

  defp dataset_urn(name, platform) do
    "urn:li:dataset:(#{platform_urn(platform)},#{name},#{env()})"
  end

  defp tag_urn(tag) do
    "urn:li:tag:#{tag}"
  end

  defp user_urn(user) do
    "urn:li:corpuser:#{user}"
  end

  defp platform_urn(platform) do
    "urn:li:dataPlatform:#{platform}"
  end

  defp dataset_proposal(dataset_urn, opts) do
    aspect_name = Keyword.get(opts, :aspect_name)
    aspect = Keyword.get(opts, :aspect)

    if aspect && aspect_name do
      %{
        proposal: %{
          entityUrn: dataset_urn,
          entityType: "dataset",
          aspectName: aspect_name,
          changeType: "UPSERT",
          aspect: %{
            contentType: "application/json",
            value: Jason.encode!(aspect)
          }
        }
      }
    else
      %{
        proposal: %{
          entityUrn: dataset_urn,
          entityType: "dataset",
          changeType: "UPSERT"
        }
      }
    end
  end

  defp env() do
    if Application.get_env(:ingest, :environment) == :dev do
      "DEV"
    else
      "PROD"
    end
  end
end
