defmodule Ingest.RequestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ingest.Requests` context.
  """
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a template.
  """
  def template_fixture(attrs \\ %{}) do
    {:ok, user} =
      Ingest.Accounts.register_user(%{
        email: unique_user_email(),
        password: "xxxxxxxxxxxx",
        name: "Administrator"
      })

    {:ok, template} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        inserted_by: user.id
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
        status: :draft,
        project_id: Ingest.ProjectsFixtures.project_fixture().id
      })
      |> Ingest.Requests.create_request()

    request
  end
end
