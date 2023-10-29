defmodule Ingest.AccessTest do
  use Ingest.DataCase

  alias Ingest.Access

  describe "policies" do
    alias Ingest.Access.Policy

    import Ingest.AccessFixtures

    @invalid_attrs %{attributes: nil, name: nil, actions: nil, resource_types: nil, matcher: nil}

    test "list_global_policies/2 returns policies matching resources and action" do
      valid_attrs = %{
        attributes: [],
        name: "some name",
        actions: [:update],
        resource_types: [Ingest.Access.Policy],
        matcher: :match_all,
        scope: :global
      }

      assert {:ok, %Policy{} = policy} = Access.create_policy(valid_attrs)

      assert policies =
               Access.list_policies(schemas: [Ingest.Access.Policy], actions: [:update])

      assert length(policies) > 0
      assert Enum.at(policies, 0).matcher == :match_all
      assert Enum.at(policies, 0).resource_types == [Ingest.Access.Policy]

      # it's not coverage unless you test failure
      assert policies =
               Access.list_policies(schemas: [Ingest.Access.Policy], actions: [:create])

      assert length(policies) == 0
    end

    test "list_policies/0 returns all policies" do
      policy = policy_fixture()
      assert Access.list_policies() == [policy]
    end

    test "get_policy!/1 returns the policy with given id" do
      policy = policy_fixture()
      assert Access.get_policy!(policy.id) == policy
    end

    test "create_policy/1 with valid data creates a policy" do
      valid_attrs = %{
        attributes: [],
        name: "some name",
        actions: [:update],
        resource_types: [Ingest.Access.Policy],
        matcher: :match_all,
        scope: :global
      }

      assert {:ok, %Policy{} = policy} = Access.create_policy(valid_attrs)
      assert policy.attributes == []
      assert policy.name == "some name"
      assert policy.actions == [:update]
      assert policy.resource_types == [Ingest.Access.Policy]
      assert policy.matcher == :match_all
    end

    test "create_policy/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Access.create_policy(@invalid_attrs)
    end

    test "update_policy/2 with valid data updates the policy" do
      policy = policy_fixture()

      update_attrs = %{
        attributes: [],
        name: "some updated name",
        actions: [:delete],
        resource_types: [Ingest.Access.Policy],
        matcher: :match_one,
        scope: :global
      }

      assert {:ok, %Policy{} = policy} = Access.update_policy(policy, update_attrs)
      assert policy.attributes == []
      assert policy.name == "some updated name"
      assert policy.actions == [:delete]
      assert policy.resource_types == [Ingest.Access.Policy]
      assert policy.matcher == :match_one
    end

    test "update_policy/2 with invalid data returns error changeset" do
      policy = policy_fixture()
      assert {:error, %Ecto.Changeset{}} = Access.update_policy(policy, @invalid_attrs)
      assert policy == Access.get_policy!(policy.id)
    end

    test "delete_policy/1 deletes the policy" do
      policy = policy_fixture()
      assert {:ok, %Policy{}} = Access.delete_policy(policy)
      assert_raise Ecto.NoResultsError, fn -> Access.get_policy!(policy.id) end
    end

    test "change_policy/1 returns a policy changeset" do
      policy = policy_fixture()
      assert %Ecto.Changeset{} = Access.change_policy(policy)
    end
  end

  describe "resource_policies" do
    alias Ingest.Access.ResourcePolicy

    import Ingest.AccessFixtures

    @invalid_attrs %{resource_id: nil, resource_type: nil}

    test "list_resource_policies/0 returns all resource_policies" do
      resource_policy = resource_policy_fixture()
      assert Access.list_resource_policies() == [resource_policy]
    end

    test "create_resource_policy/1 with valid data creates a resource_policy" do
      valid_attrs = %{
        resource_id: "7488a646-e31f-11e4-aace-600308960662",
        resource_type: "some resource_type"
      }

      assert {:ok, %ResourcePolicy{} = resource_policy} =
               Access.create_resource_policy(valid_attrs)

      assert resource_policy.resource_id == "7488a646-e31f-11e4-aace-600308960662"
      assert resource_policy.resource_type == "some resource_type"
    end

    test "create_resource_policy/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Access.create_resource_policy(@invalid_attrs)
    end
  end
end
