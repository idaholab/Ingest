defmodule Ingest.Destinations.S3Config do
  @moduledoc """
  S3 bucket configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :access_key_id, Ingest.Encrypted.Binary
    field :secret_access_key, Ingest.Encrypted.Binary
    field :region, Ingest.Encrypted.Binary
    field :base_url, Ingest.Encrypted.Binary
    field :bucket, Ingest.Encrypted.Binary
    field :path, Ingest.Encrypted.Binary
    field :final_path, Ingest.Encrypted.Binary
    field :ssl, :boolean, default: true
    field :integrated_metadata, :boolean, default: false
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(
      attrs,
      [
        :access_key_id,
        :secret_access_key,
        :bucket,
        :region,
        :base_url,
        :path,
        :final_path,
        :ssl,
        :integrated_metadata
      ],
      empty_values: [""]
    )
    |> validate_required([:bucket, :path])
  end
end

defmodule Ingest.Destinations.S3ConfigAdditional do
  @moduledoc """
  S3 compliant gateway additional configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    # often we need to provide a name as a slug, so that users or admins can specify
    # how a project/request will be named in the root storage mechanism
    #
    # S3 Specific: this is the name of the root folder in which the data will be
    # housed for this shared destination
    field :folder_name, :string
    field :integrated_metadata, :boolean, default: false
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(
      attrs,
      [
        :folder_name,
        :integrated_metadata
      ],
      empty_values: [""]
    )
    |> validate_required([:folder_name])
  end
end

defmodule Ingest.Destinations.AzureConfig do
  @moduledoc """
  Azure blob/datalake configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :account_name, Ingest.Encrypted.Binary
    field :account_key, Ingest.Encrypted.Binary
    field :base_url, Ingest.Encrypted.Binary
    field :ssl, :boolean, default: true
    field :container, Ingest.Encrypted.Binary
    field :integrated_metadata, :boolean, default: false
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(
      attrs,
      [
        :account_name,
        :account_key,
        :base_url,
        :container,
        :ssl,
        :integrated_metadata
      ],
      empty_values: [""]
    )
    |> validate_required([:container])
  end
end

defmodule Ingest.Destinations.AzureConfigAdditional do
  @moduledoc """
  Azure blob/datalake additional configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    # often we need to provide a name as a slug, so that users or admins can specify
    # how a project/request will be named in the root storage mechanism
    #
    # Azure Specific: this is the name of the root folder in which the data will be
    # housed for this shared destination
    field :folder_name, :string
    field :integrated_metadata, :boolean, default: false
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(
      attrs,
      [
        :folder_name,
        :integrated_metadata
      ],
      empty_values: [""]
    )
    |> validate_required([:folder_name])
  end
end

defmodule Ingest.Destinations.LakeFSConfig do
  @moduledoc """
  LakeFS configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :access_key_id, Ingest.Encrypted.Binary
    field :secret_access_key, Ingest.Encrypted.Binary
    field :region, Ingest.Encrypted.Binary
    field :base_url, Ingest.Encrypted.Binary
    field :repository, Ingest.Encrypted.Binary
    field :port, :integer, default: nil
    field :ssl, :boolean, default: true
    field :integrated_metadata, :boolean, default: false
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(
      attrs,
      [
        :access_key_id,
        :secret_access_key,
        :repository,
        :base_url,
        :port,
        :ssl,
        :region,
        :integrated_metadata
      ],
      empty_values: [""]
    )
    |> validate_required([:base_url, :repository])
  end
end

defmodule Ingest.Destinations.LakeFSConfigAdditional do
  @moduledoc """
  LakeFS additional configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    # often we need to provide a name as a slug, so that users or admins can specify
    # how a project/request will be named in the root storage mechanism
    #
    # LakeFS Specific: this is the name of the repository this data will be stored in
    field :repository_name, :string

    #  email given here will be given the repository admin privilege on the resulting LakeFS repository
    field :repository_owner_email, :string

    # whether or not we should use our lakefs credentials and make groups and policies for
    # this new repository connection
    field :generate_permissions, :boolean, default: true
    field :integrated_metadata, :boolean, default: false
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(
      attrs,
      [
        :repository_name,
        :repository_owner_email,
        :generate_permissions,
        :integrated_metadata
      ],
      empty_values: [""]
    )
    |> validate_required([:repository_name])
    |> validate_email()
  end

  def validate_email(changeset) do
    changeset
    |> validate_required([:repository_owner_email])
    |> validate_format(:repository_owner_email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:repository_owner_email, max: 160)
  end
end

defmodule Ingest.Destinations.TemporaryConfig do
  @moduledoc """
  Temporary storage configuration
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :limit, :integer
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:limit])
    |> validate_required([:limit])
    |> validate_number(:limit, less_than_or_equal_to: 30)
  end
end
