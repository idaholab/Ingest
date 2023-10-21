defmodule Ingest.Access.Policy do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "policies" do
    field :attributes, :map
    field :name, :string
    field :actions, {:array, Ecto.Enum}, values: [:create, :read, :update, :delete]
    field :scope, Ecto.Enum, values: [:global, :user, :group]
    field :scope_id, :binary_id
    field :resource_types, {:array, EctoResourceType}
    field :matcher, Ecto.Enum, values: [:match_one, :match_none, :match_all]

    many_to_many :resource_policies, Ingest.Access.ResourcePolicy,
      join_through: "resource_policies"

    timestamps()
  end

  @doc false
  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [:name, :actions, :resource_types, :attributes, :matcher, :scope])
    |> validate_required([:name, :actions, :resource_types, :matcher, :scope])
  end
end
