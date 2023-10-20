defmodule EctoResourceType do
  use Ecto.Type
  def type, do: :string

  # Provide custom casting rules.
  def cast(resource_type) when is_binary(resource_type) do
    {:ok, resource_type |> String.to_existing_atom()}
  end

  # if we're already an atom move on
  def cast(resource_type) when is_atom(resource_type) do
    {:ok, resource_type}
  end

  # Everything else is a failure
  def cast(_), do: :error

  # Coming from the db everything should be a string for this type
  def load(data) when is_binary(data) do
    {:ok, data |> String.to_existing_atom()}
  end

  # When dumping data to the database, we *expect* a URI struct
  # but any value could be inserted into the schema struct at runtime,
  # so we need to guard against them.
  def dump(data) when is_atom(data) do
    {:ok, data |> to_string}
  end

  # accept strings
  def dump(data) when is_binary(data) do
    {:ok, data}
  end

  def dump(_), do: :error
end
