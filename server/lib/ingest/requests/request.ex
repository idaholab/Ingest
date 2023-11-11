defmodule Ingest.Requests.Request do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ingest.Accounts.User
  alias Ingest.Projects.Project
  alias Ingest.Requests.Template

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "requests" do
    field :name, :string
    field :public, :boolean, default: false
    field :status, Ecto.Enum, values: [:draft, :published]
    field :description, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by

    # even though these say "belongs_to" it really represents a one-to-one or many-to-one association
    belongs_to :template, Template, type: :binary_id, foreign_key: :template_id
    belongs_to :project, Project, type: :binary_id, foreign_key: :project_id

    timestamps()
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [:name, :description, :status, :public])
    |> validate_required([:name, :description, :status, :public])
  end
end
