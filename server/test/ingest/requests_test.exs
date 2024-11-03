defmodule Ingest.RequestsTest do
  use Ingest.DataCase, async: false

  alias Ingest.Requests

  describe "templates" do
    alias Ingest.Requests.Template

    import Ingest.RequestsFixtures

    @invalid_attrs %{name: nil, description: nil, structure: nil}

    test "list_templates/0 returns all templates" do
      template = template_fixture()
      assert Enum.member?(Requests.list_templates(), template)
    end

    test "get_template!/1 returns the template with given id" do
      template = template_fixture()
      assert Requests.get_template!(template.id) == template
    end

    test "create_template/1 with valid data creates a template" do
      {:ok, user} =
        Ingest.Accounts.register_user(%{
          email: unique_user_email(),
          password: "xxxxxxxxxxxx",
          name: "Administrator"
        })

      valid_attrs = %{
        name: "some name",
        description: "some description",
        inserted_by: user.id
      }

      assert {:ok, %Template{} = template} = Requests.create_template(valid_attrs)
      assert template.name == "some name"
      assert template.description == "some description"
    end

    test "create_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Requests.create_template(@invalid_attrs)
    end

    test "update_template/2 with valid data updates the template" do
      template = template_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %Template{} = template} = Requests.update_template(template, update_attrs)
      assert template.name == "some updated name"
      assert template.description == "some updated description"
    end

    test "update_template/2 with invalid data returns error changeset" do
      template = template_fixture()
      assert {:error, %Ecto.Changeset{}} = Requests.update_template(template, @invalid_attrs)
      assert template == Requests.get_template!(template.id)
    end

    test "delete_template/1 deletes the template" do
      template = template_fixture()
      assert {:ok, %Template{}} = Requests.delete_template(template)
      assert_raise Ecto.NoResultsError, fn -> Requests.get_template!(template.id) end
    end

    test "change_template/1 returns a template changeset" do
      template = template_fixture()
      assert %Ecto.Changeset{} = Requests.change_template(template)
    end
  end

  describe "requests" do
    alias Ingest.Requests.Request

    import Ingest.RequestsFixtures

    @invalid_attrs %{name: nil, public: nil, status: nil, description: nil}

    test "get_request!/1 returns the request with given id" do
      request = request_fixture()
      assert Requests.get_request!(request.id).name == request.name
    end

    test "create_request/1 with valid data creates a request" do
      valid_attrs = %{
        name: "some name",
        status: :draft,
        description: "some description",
        project_id: Ingest.ProjectsFixtures.project_fixture().id
      }

      assert {:ok, %Request{} = request} = Requests.create_request(valid_attrs)
      assert request.name == "some name"
      assert request.status == :draft
      assert request.description == "some description"
    end

    test "create_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Requests.create_request(@invalid_attrs)
    end

    test "update_request/2 with valid data updates the request" do
      request = request_fixture()

      update_attrs = %{
        name: "some updated name",
        public: false,
        status: :published,
        description: "some updated description"
      }

      assert {:ok, %Request{} = request} = Requests.update_request(request, update_attrs)
      assert request.name == "some updated name"
      assert request.status == :published
      assert request.description == "some updated description"
    end

    test "update_request/2 with invalid data returns error changeset" do
      request = request_fixture()
      assert {:error, %Ecto.Changeset{}} = Requests.update_request(request, @invalid_attrs)
      assert request.name == Requests.get_request!(request.id).name
    end

    test "delete_request/1 deletes the request" do
      request = request_fixture()
      assert {:ok, %Request{}} = Requests.delete_request(request)
      assert_raise Ecto.NoResultsError, fn -> Requests.get_request!(request.id) end
    end

    test "change_request/1 returns a request changeset" do
      request = request_fixture()
      assert %Ecto.Changeset{} = Requests.change_request(request)
    end
  end

  describe "template_members" do
    alias Ingest.Requests.TemplateMembers

    import Ingest.RequestsFixtures

    @invalid_attrs %{role: nil}

    test "list_template_members/0 returns all template_members" do
      template_members = template_members_fixture()
      assert Enum.member?(Requests.list_template_members(), template_members)
    end

    test "create_template_members/1 with valid data creates a template_members" do
      valid_attrs = %{role: :member, template_id: template_fixture().id}

      assert {:ok, %TemplateMembers{} = template_members} =
               Requests.create_template_members(valid_attrs)

      assert template_members.role == :member
    end

    test "create_template_members/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Requests.create_template_members(@invalid_attrs)
    end

    test "change_template_members/1 returns a template_members changeset" do
      template_members = template_members_fixture()
      assert %Ecto.Changeset{} = Requests.change_template_members(template_members)
    end
  end
end
