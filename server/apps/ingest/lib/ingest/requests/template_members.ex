defmodule Ingest.Requests.TemplateMembers do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type :binary_id
  schema "template_members" do
    field :role, Ecto.Enum, values: [:editor, :member]
    field :email, :string
    belongs_to :template, Ingest.Requests.Template, foreign_key: :template_id, type: :binary_id
    belongs_to :user, Ingest.Accounts.User, foreign_key: :user_id, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(template_members, attrs) do
    template_members
    |> cast(attrs, [:role, :template_id, :user_id, :email])
    |> validate_required([:role, :template_id])
  end
end
