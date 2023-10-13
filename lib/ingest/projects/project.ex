defmodule Ingest.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ingest.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    field :status, :string
    field :description, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :status, :description])
    |> validate_required([:name, :status, :description])
  end
end
