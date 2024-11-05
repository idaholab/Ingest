defmodule Ingest.Requests.Template do
  @moduledoc """
  Template is the root database recoord for data templates. Data templates are attached to
  data requests and control how a form is created and built for user uploads.
  """
  @behaviour Bodyguard.Policy

  use Ecto.Schema
  import Ecto.Changeset
  alias Ingest.Requests.Template
  alias Ingest.Requests.TemplateField
  alias Ingest.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "templates" do
    field :name, :string
    field :description, :string

    belongs_to :user, User, type: :binary_id, foreign_key: :inserted_by
    embeds_many :fields, TemplateField, on_replace: :delete

    many_to_many :template_members, User,
      join_through: "template_members",
      join_keys: [template_id: :id, user_id: :id]

    timestamps()
  end

  @doc false
  def changeset(%Template{} = template, attrs, _meta \\ %{}) do
    template
    |> cast(attrs, [:name, :description, :inserted_by])
    |> cast_embed(:fields, required: false, on_replace: :delete_if_exists)
    |> validate_required([:name, :inserted_by])
  end

  def authorize(:create_template, _user), do: :ok

  # Admins can do anything
  def authorize(action, %{roles: :admin} = _user, _project)
      when action in [:update_template, :delete_template],
      do: :ok

  # Users can manage their own request or ones they're members of
  def authorize(
        action,
        %{id: user_id} = user,
        %{id: template_id, inserted_by: owner} = _template
      )
      when action in [:update_template] do
    user_id == owner ||
      Enum.member?(
        [:editor, :member],
        Ingest.Requests.get_owned_template!(user, template_id).role
      )
  end

  def authorize(
        action,
        %{id: user_id} = user,
        %{id: template_id, inserted_by: owner} = _template
      )
      when action in [:delete_template] do
    user_id == owner ||
      Enum.member?(
        [:editor],
        Ingest.Requests.get_owned_template!(user, template_id).role
      )
  end

  # Otherwise, denied
  def authorize(_, _, _), do: :error
end

defmodule Ingest.Requests.TemplateSearch do
  @moduledoc """
  Reflects the virtual table for FTS5 trigram searching.
  """
  use Ecto.Schema

  @primary_key false
  schema "templates_search" do
    field :rowid, :integer
    field :id, :binary_id
    field :name, :string
    field :description, :string
    field :rank, :float, virtual: true
  end
end

defmodule Ingest.Requests.TemplateField do
  @moduledoc """
  TemplateField represents the the fields we use the build the form for the user uploading files
  to Ingest. It contains all information needed to build the form correctly on the UI and capture
  user's input correctly.
  """
  alias Ingest.Requests.TemplateField
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :label, :string
    field :help_text, :string

    field :type, Ecto.Enum,
      values: [:select, :text, :number, :textarea, :checkbox, :date, :branch]

    field :select_options, {:array, :string}, default: []
    # the map has two keys, template and name
    field :branch_options, {:array, :map}, default: []
    field :required, :boolean
    field :file_extensions, {:array, :string}
  end

  def changeset(%TemplateField{} = field, attrs) do
    field
    |> cast(attrs, [
      :label,
      :help_text,
      :type,
      :select_options,
      :branch_options,
      :required,
      :file_extensions
    ])
    |> validate_required([:label, :type])
  end
end
