defmodule Ingest.DataHubTest do
  @moduledoc """
  All tests related to DataHub module.
  """
  use ExUnit.Case, async: true
  alias Ingest.DataHub

  test "it creates a dataset" do
    event = DataHub.create_dataset_event("testingProject.test", "lakefs")
    assert {:ok, _created} = DataHub.send_event(event)
  end

  test "it can add properties to a dataset" do
    event =
      DataHub.create_dataset_event(:properties, "testingProject.test", "lakefs",
        name: "Testing Dataset",
        description: "A testing dataset set by LiveBook",
        custom: %{custom: "Custom Property"}
      )

    assert {:ok, _created} = DataHub.send_event(event)
  end

  test "it can add owners to a dataset" do
    event =
      DataHub.create_dataset_event(:owners, "testingProject.test", "lakefs",
        owners: ["John.Darrington@inl.gov"]
      )

    assert {:ok, _created} = DataHub.send_event(event)
  end

  test "it can add tags to a dataset" do
    event =
      DataHub.create_dataset_event(:tags, "testingProject.test", "lakefs",
        tags: ["test tag 1", "test tag 2"]
      )

    assert {:ok, _created} = DataHub.send_event(event)
  end

  test "it can add a project to a dataset" do
    event =
      DataHub.create_dataset_event(:project, "testingProject.test", "lakefs",
        name: "Test Project",
        description: "A Testing Project"
      )

    assert {:ok, _created} = DataHub.send_event(event)
  end

  test "it can add a download link to a dataset" do
    event =
      DataHub.create_dataset_event(:download_link, "testingProject.test", "lakefs",
        repo: "test",
        branch: "main",
        filename: "test.csv",
        endpoint: "http://localhost:3000",
        email: "test@test.com"
      )

    assert {:ok, _created} = DataHub.send_event(event)
  end

  test "it can add a generic schema to a dataset" do
    event =
      DataHub.create_dataset_event(:schema, "schematest", "lakefs",
        name: "Test Schema",
        version: 0,
        fields: [
          %{
            fieldPath: "name",
            nativeDataType: "string",
            type: %{type: %{DataHub.linkedin_data_type(:string) => %{}}}
          },
          %{
            fieldPath: "age",
            nativeDataType: "number",
            type: %{type: %{DataHub.linkedin_data_type(:number) => %{}}}
          }
        ]
      )

    assert {:ok, _created} = DataHub.send_event(event)
  end

  test "it fetches a download link for a dataset" do
    # TODO: replace with your URN
    assert {:ok, link} =
             DataHub.get_download_link(
               "urn:li:dataset:(urn:li:dataPlatform:lakefs,spark-sql2.cmd,DEV)"
             )

    assert Map.has_key?(link, "branch")
    assert Map.has_key?(link, "repo")
    assert Map.has_key?(link, "filename")
    assert Map.has_key?(link, "endpoint")
    assert Map.has_key?(link, "contact_email")
  end

  test "it deletes a dataset" do
    assert {:ok, _deleted} = DataHub.delete_dataset("testingProject.test", "lakefs")
  end
end
