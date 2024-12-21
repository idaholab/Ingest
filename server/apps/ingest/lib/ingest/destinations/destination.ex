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
    field :type, Ecto.Enum, values: [:s3, :azure, :lakefs], default: :s3
    field :visibility, Ecto.Enum, values: [:public, :private], default: :private

    field :status, Ecto.Enum,
      values: [:accepted, :rejected, :pending, :not_requested],
      virtual: true,
      default: :not_requested

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
    d = Ingest.Destinations.check_owned_destination!(user, destination_id)

    cond do
      user_id == owner ->
        true

      d ->
        Enum.member?(
          [:manager, :uploader],
          d.role
        ) && d.status == :accepted

      true ->
        false
    end
  end

  # Users can manage their own destinations
  def authorize(
        action,
        %{id: user_id} = user,
        %{inserted_by: owner, id: destination_id} = _destination
      )
      when action in [:update_destination, :delete_destination] do
    d = Ingest.Destinations.check_owned_destination!(user, destination_id)

    cond do
      user_id == owner ->
        true

      d ->
        Enum.member?(
          [:manager],
          d.role
        ) && d.status == :accepted

      true ->
        false
    end
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
