defmodule Ingest.Accounts.UserKeys do
  @moduledoc """
  UserKeys are how we utilize the S3 and AzureBlob storage proxy mechanism, without having to expose the destination's
  keys and access information to the end user.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @hash_algorithm :sha256
  @rand_size 32

  @primary_key false
  @foreign_key_type :binary_id
  schema "user_keys" do
    field :access_key, :string, primary_key: true
    field :secret_key, Ingest.Encrypted.Binary

    field :expires, :utc_datetime_usec,
      default:
        DateTime.utc_now() |> DateTime.add(7_776_000, :second, Calendar.get_time_zone_database())

    belongs_to :user, Ingest.Accounts.User, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(user_keys, attrs) do
    user_keys
    |> cast(
      Map.merge(%{secret_key: build_hashed_secret_key(), access_key: UUID.uuid4(:hex)}, attrs),
      [
        :access_key,
        :secret_key,
        :expires
      ]
    )
    |> cast_assoc(:user)
    |> validate_required([:access_key, :secret_key, :expires])
  end

  defp build_hashed_secret_key() do
    token = :crypto.strong_rand_bytes(@rand_size)
    :crypto.hash(@hash_algorithm, token) |> Base.encode64()
  end
end
