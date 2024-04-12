defmodule Ingest.Imports do
  @moduledoc """
  Functions for interacting with Import Jobs table.
  """
  alias Ingest.Imports.Import
  alias Ingest.Repo

  def create_import(attrs \\ %{}) do
    %Import{}
    |> Import.changeset(attrs)
    |> Repo.insert()
  end
end
