defmodule Ingest.Requests.Template do
  @moduledoc """
  Template is the root database recoord for data templates. Data templates are attached to
  data requests and control how a form is created and built for user uploads.
  """
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
    embeds_many :fields, TemplateField

    timestamps()
  end

  @doc false
  def changeset(%Template{} = template, attrs) do
    template
    |> cast(attrs, [:name, :description, :inserted_by])
    |> cast_embed(:fields, required: false, on_replace: :delete_if_exists)
    |> validate_required([:name, :inserted_by])
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
    field :type, Ecto.Enum, values: [:select, :text, :number, :textarea, :checkbox, :date]
    field :select_options, {:array, :string}
    field :required, :boolean
    field :per_file, :boolean
    field :file_extensions, {:array, :string}
  end

  def changeset(%TemplateField{} = field, attrs) do
    field
    |> cast(attrs, [
      :label,
      :help_text,
      :type,
      :select_options,
      :required,
      :per_file,
      :file_extensions
    ])
    |> validate_required([:label, :type])
  end
end
