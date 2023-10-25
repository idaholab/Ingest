defmodule Ingest.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ingest.Accounts.User
  alias Ingest.Requests.Request

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    field :description, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by
    has_many :requests, Request

    many_to_many :project_members, Ingest.Accounts.User,
      join_through: "project_members",
      join_keys: [project_id: :id, member_id: :user_id]

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :inserted_by])
    |> validate_required([:name, :description])
  end
end
