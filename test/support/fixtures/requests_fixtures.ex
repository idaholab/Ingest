defmodule Ingest.RequestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ingest.Requests` context.
  """

  @doc """
  Generate a template.
  """
  def template_fixture(attrs \\ %{}) do
    {:ok, template} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        structure: %{}
      })
      |> Ingest.Requests.create_template()

    template
  end

  @doc """
  Generate a request.
  """
  def request_fixture(attrs \\ %{}) do
    {:ok, request} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        public: true,
        status: "some status"
      })
      |> Ingest.Requests.create_request()

    request
  end
end
