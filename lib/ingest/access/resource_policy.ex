defmodule Ingest.Access.ResourcePolicy do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resource_policies" do
    field :resource_id, Ecto.UUID
    field :resource_type, :string
    field :policy_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(resource_policy, attrs) do
    resource_policy
    |> cast(attrs, [:resource_id, :resource_type])
    |> validate_required([:resource_id, :resource_type])
  end
end
