defmodule Ingest.Accounts.Notifications do
  @moduledoc """
  Notifications represent system notifications generated from various actions performed by the system
  """
  alias Ingest.Accounts.User
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notifications" do
    field :body, :string
    field :seen, :boolean, default: false
    field :subject, :string
    field :action_link, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :user_id

    timestamps()
  end

  @doc false
  def changeset(notifications, attrs) do
    notifications
    |> cast(attrs, [:subject, :body, :seen, :action_link])
    |> validate_required([:subject, :body, :seen])
  end
end
