defmodule AzureStorage.Container do
  @moduledoc """
  All operations and program flow for the Containers object in Azure storage.
  https://learn.microsoft.com/en-us/rest/api/storageservices/operations-on-containers
  """
  alias __MODULE__

  @enforce_keys [:name]
  defstruct [
    :name
  ]

  @doc """
  new simply creates a new Container struct with the given arguments, but does not create
  it in the storage account.
  """
  def new(name) do
    # can eventually add checks to make sure the container exists, and the name is valid etc.
    # options to create if it does not exist etc.
    %Container{
      name: name
    }
  end
end
