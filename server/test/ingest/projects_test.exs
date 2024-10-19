defmodule Ingest.ProjectsTest do
  use Ingest.DataCase

  alias Ingest.Projects

  describe "project" do
    alias Ingest.Projects.Project

    import Ingest.ProjectsFixtures

    @invalid_attrs %{name: nil, status: nil, description: nil}

    test "list_project/0 returns all project" do
      project = project_fixture()
      assert Enum.member?(Projects.list_project(), project)
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Projects.get_project!(project.id).id == project.id
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.name == "some name"
      assert project.description == "some description"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)
      assert project.name == "some updated name"
      assert project.description == "some updated description"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project.name == Projects.get_project!(project.id).name
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end

  describe "project_invites" do
    alias Ingest.Projects.ProjectInvites

    import Ingest.ProjectsFixtures

    @invalid_attrs %{email: nil}

    test "get_project_invites!/1 returns the project_invites with given id" do
      project_invites = project_invites_fixture(Ingest.AccountsFixtures.user_fixture())
      assert Projects.get_project_invites!(project_invites.id) == project_invites
    end

    test "create_project_invites/1 with valid data creates a project_invites" do
      valid_attrs = %{email: "some email"}

      assert {:ok, %ProjectInvites{} = project_invites} =
               Projects.create_project_invites(valid_attrs)

      assert project_invites.email == "some email"
    end

    test "create_project_invites/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project_invites(@invalid_attrs)
    end

    test "update_project_invites/2 with valid data updates the project_invites" do
      project_invites = project_invites_fixture(Ingest.AccountsFixtures.user_fixture())
      update_attrs = %{email: "some updated email"}

      assert {:ok, %ProjectInvites{} = project_invites} =
               Projects.update_project_invites(project_invites, update_attrs)

      assert project_invites.email == "some updated email"
    end

    test "update_project_invites/2 with invalid data returns error changeset" do
      project_invites = project_invites_fixture(Ingest.AccountsFixtures.user_fixture())

      assert {:error, %Ecto.Changeset{}} =
               Projects.update_project_invites(project_invites, @invalid_attrs)

      assert project_invites == Projects.get_project_invites!(project_invites.id)
    end

    test "delete_project_invites/1 deletes the project_invites" do
      project_invites = project_invites_fixture(Ingest.AccountsFixtures.user_fixture())
      assert {:ok, %ProjectInvites{}} = Projects.delete_project_invites(project_invites)

      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_project_invites!(project_invites.id)
      end
    end

    test "change_project_invites/1 returns a project_invites changeset" do
      project_invites = project_invites_fixture(Ingest.AccountsFixtures.user_fixture())
      assert %Ecto.Changeset{} = Projects.change_project_invites(project_invites)
    end
  end
end
