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
    field :visibility, Ecto.Enum, values: [:public, :private], default: :private

    field :classifications_allowed, {:array, Ecto.Enum},
      values: Application.compile_env(:ingest, :data_classifications)

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by
    embeds_one :s3_config, S3Config, on_replace: :update
    embeds_one :azure_config, AzureConfig, on_replace: :update
    embeds_one :lakefs_config, LakeFSConfig, on_replace: :update
    embeds_one :temporary_config, TemporaryConfig, on_replace: :update

    many_to_many :destination_members, User,
      join_through: "destination_members",
      join_keys: [destination_id: :id, user_id: :id]

    timestamps()
  end

  @doc false
  def display_changeset(destination, attrs) do
    if destination.classifications_allowed do
      destination
      |> cast(attrs, [:name, :type, :inserted_by, :classifications_allowed, :visibility])
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
      |> cast(attrs, [:name, :type, :inserted_by, :classifications_allowed, :visibility])
      |> cast_embed(:s3_config, require: false)
      |> cast_embed(:azure_config, require: false)
      |> cast_embed(:lakefs_config, required: false)
      |> cast_embed(:temporary_config, required: false)
      |> validate_required([:name, :type])
    end
  end

  def changeset(destination, attrs) do
    destination
    |> cast(attrs, [:name, :type, :inserted_by, :classifications_allowed, :visibility])
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

  # who can use a destination - managers, uploaders and owners
  def authorize(
        action,
        %{id: user_id} = user,
        %{id: destination_id, inserted_by: owner} = _destination
      )
      when action in [:use_destination] do
    user_id == owner ||
      Enum.member?(
        [:manager, :uploader],
        Ingest.Destinations.check_owned_destination!(user, destination_id).role
      )
  end

  # Users can manage their own destinations
  def authorize(
        action,
        %{id: user_id} = user,
        %{inserted_by: owner, id: destination_id} = _destination
      )
      when action in [:update_destination, :delete_destination] do
    dbg(Ingest.Destinations.check_owned_destination!(user, destination_id))

    user_id == owner ||
      Enum.member?(
        [:manager],
        Ingest.Destinations.check_owned_destination!(user, destination_id).role
      )
  end

  # Otherwise, denied
  def authorize(_, _, _), do: :error
end

defmodule Ingest.Destinations.DestinationSearch do
  @moduledoc """
  Reflects the virtual table for FTS5 trigram searching.
  """
  use Ecto.Schema

  @primary_key false
  schema "destinations_search" do
    field :rowid, :integer
    field :id, :binary_id
    field :name, :string
    field :rank, :float, virtual: true
  end
end

defmodule Ingest.Destinations.S3Config do
  @moduledoc """
  S3 bucket configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :access_key_id, Ingest.Encrypted.JSONBinary
    field :secret_access_key, Ingest.Encrypted.JSONBinary
    field :region, Ingest.Encrypted.JSONBinary
    field :base_url, Ingest.Encrypted.JSONBinary
    field :bucket, Ingest.Encrypted.JSONBinary
    field :path, Ingest.Encrypted.JSONBinary
    field :final_path, Ingest.Encrypted.JSONBinary
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

defmodule Ingest.Destinations.AzureConfig do
  @moduledoc """
  Azure blob/datalake configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :account_name, Ingest.Encrypted.JSONBinary
    field :account_key, Ingest.Encrypted.JSONBinary
    field :base_url, Ingest.Encrypted.JSONBinary
    field :ssl, :boolean, default: true
    field :container, Ingest.Encrypted.JSONBinary
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

defmodule Ingest.Destinations.LakeFSConfig do
  @moduledoc """
  LakeFS configuration storage
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :access_key_id, Ingest.Encrypted.JSONBinary
    field :secret_access_key, Ingest.Encrypted.JSONBinary
    field :region, Ingest.Encrypted.JSONBinary
    field :base_url, Ingest.Encrypted.JSONBinary
    field :repository, Ingest.Encrypted.JSONBinary
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
