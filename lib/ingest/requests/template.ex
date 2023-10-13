defmodule Ingest.Requests.Template do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ingest.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "templates" do
    field :name, :string
    field :description, :string
    field :structure, :map

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :description, :structure])
    |> validate_required([:name, :structure])
  end
end
