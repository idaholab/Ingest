defmodule Ingest.Destinations.Destination do
  @moduledoc """
  Destination represents the destination for data that's been uploaded to the system.
  Typically this reflects the HTTP uploads, but can hopefully be configured in the future
  to work with the high-speed UDP file transers as well.
  """
  @behaviour Bodyguard.Policy

  alias Ingest.Destinations.LakeFSConfig
  alias Ingest.Destinations.TemporaryConfig
  alias Ingest.Destinations.AzureConfig
  alias Ingest.Destinations.S3Config
  alias Ingest.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "destinations" do
    field :name, :string
    # internal storage are those methods provided by the Ingest application administrators
    field :type, Ecto.Enum, values: [:s3, :azure, :temporary, :lakefs], default: :s3

    field :classifications_allowed, {:array, Ecto.Enum},
      values: Application.compile_env(:ingest, :data_classifications)

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by
    embeds_one :s3_config, S3Config
    embeds_one :azure_config, AzureConfig
    embeds_one :lakefs_config, LakeFSConfig
    embeds_one :temporary_config, TemporaryConfig

    timestamps()
  end

  @doc false
  def display_changeset(destination, attrs) do
    if destination.classifications_allowed do
      destination
      |> cast(attrs, [:name, :type, :inserted_by, :classifications_allowed])
      |> cast(
        Enum.map(destination.classifications_allowed, fn c -> {c, true} end) |> Map.new(),
        []
      )
      |> cast_embed(:s3_config, require: false)
      |> cast_embed(:azure_config, require: false)
      |> cast_embed(:lakefs_config, required: false)
      |> cast_embed(:temporary_config, required: false)
      |> validate_required([:name, :type])
    else
      destination
      |> cast(attrs, [:name, :type, :inserted_by, :classifications_allowed])
      |> cast_embed(:s3_config, require: false)
      |> cast_embed(:azure_config, require: false)
      |> cast_embed(:lakefs_config, required: false)
      |> cast_embed(:temporary_config, required: false)
      |> validate_required([:name, :type])
    end
  end

  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [:name, :type, :inserted_by, :classifications_allowed])
    |> cast_embed(:s3_config, require: false)
    |> cast_embed(:azure_config, require: false)
    |> cast_embed(:lakefs_config, required: false)
    |> cast_embed(:temporary_config, required: false)
    |> validate_required([:name, :type])
  end

  def authorize(:create_destination, _user), do: :ok

  # Admins can do anything
  def authorize(action, %{roles: :admin} = _user, _destination)
      when action in [:update_destination, :delete_destination],
      do: :ok

  # Users can manage their own projects
  def authorize(action, %{id: user_id} = _user, %{inserted_by: user_id} = _destination)
      when action in [:update_destination, :delete_destination],
      do: :ok

  # Otherwise, denied
  def authorize(_, _, _), do: :error
end

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
    |> cast(attrs, [
      :access_key_id,
      :secret_access_key,
      :bucket,
      :region,
      :base_url,
      :path,
      :final_path,
      :ssl,
      :integrated_metadata
    ])
    |> validate_required([:bucket, :path])
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
    |> cast(attrs, [
      :account_name,
      :account_key,
      :base_url,
      :container,
      :ssl,
      :integrated_metadata
    ])
    |> validate_required([:container])
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
    |> cast(attrs, [
      :access_key_id,
      :secret_access_key,
      :repository,
      :base_url,
      :port,
      :ssl,
      :region,
      :integrated_metadata
    ])
    |> validate_required([:base_url, :repository])
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
