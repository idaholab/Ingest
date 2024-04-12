defmodule Ingest.Imports.Import do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Database for Import Jobs.
  """
  alias Ingest.Imports.BoxConfig
  alias Ingest.Imports.StandardConfig
  alias Ingest.Accounts.User
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "import_jobs" do
    field :request_id, :binary_id
    field :errors, {:array, :string}
    field :status, Ecto.Enum, values: [:success, :error]

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by

    embeds_one :box_config, BoxConfig
    embeds_one :standard_config, StandardConfig

    timestamps()
  end

  @doc false
  def changeset(import, attrs) do
    import
    |> cast(attrs, [:request_id, :inserted_by, :errors, :status])
    |> cast_embed(:box_config, require: false)
    |> cast_embed(:standard_config, require: false)
  end
end

defmodule Ingest.Imports.BoxConfig do
  @moduledoc """
  Config for Box Import
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :access_token, Ingest.Encrypted.Binary
    field :refresh_token, Ingest.Encrypted.Binary
    field :folder_id, :string
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:access_token, :refresh_token, :folder_id])
    |> validate_required([:access_token, :refresh_token, :folder_id])
  end
end

defmodule Ingest.Imports.StandardConfig do
  @moduledoc """
  Basic Config for all imports
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :access_token, :string
    field :refresh_token, :string
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:access_token, :refresh_token])
    |> validate_required([:access_token, :refresh_token])
  end
end
