defmodule Ingest.LakeFSTest do
  @moduledoc """
  Tests for the Lakefs Module.
  """
  use ExUnit.Case, async: false
  alias Ingest.LakeFS

  @tag :lakefs
  test "it can create a new repository" do
    with {:ok, client} <-
           LakeFS.new("localhost",
             port: 8000,
             access_key: "AKIAIOSFOLQUICKSTART",
             secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
           ),
         {:ok, %{"id" => id} = _repo} <-
           LakeFS.create_repo(client, "repo-name", storage_namespace: "local://test-repo") do
      assert id != ""
    end
  end

  @tag :lakefs
  test "it can protect a branch" do
    with {:ok, client} <-
           LakeFS.new("localhost",
             port: 8000,
             access_key: "AKIAIOSFOLQUICKSTART",
             secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
           ),
         {:ok, %{"id" => id} = _repo} <-
           LakeFS.create_repo(client, "repo-name", storage_namespace: "local://test-repo"),
         :ok <- LakeFS.protect_branch(client, id, "main") do
      assert id != ""
    else
      message ->
        assert is_nil(message)
    end
  end

  @tag :lakefs
  test "it can put an object in a repository" do
    with {:ok, client} <-
           LakeFS.new("localhost",
             port: 8000,
             access_key: "AKIAIOSFOLQUICKSTART",
             secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
           ),
         {:ok, %{"id" => id} = _repo} <-
           LakeFS.create_repo(client, "object-repo-name",
             storage_namespace: "local://test-repo-object"
           ),
         :ok <-
           LakeFS.put_object(
             client,
             id,
             "_lakefs_actions/actions.yaml",
             LakeFS.pre_merge_metadata_hook("test")
           ) do
      assert true
    else
      message ->
        assert is_nil(message)
    end
  end

  @tag :lakefs
  test "it can put an object in a repository and commit it" do
    with {:ok, client} <-
           LakeFS.new("localhost",
             port: 8000,
             access_key: "AKIAIOSFOLQUICKSTART",
             secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
           ),
         {:ok, %{"id" => id} = _repo} <-
           LakeFS.create_repo(client, "commit-object-repo-name",
             storage_namespace: "local://test-repo-object-commmit"
           ),
         :ok <-
           LakeFS.put_object(
             client,
             id,
             "_lakefs_actions/actions.yaml",
             LakeFS.pre_merge_metadata_hook("test")
           ),
         {:ok, commit} <- LakeFS.commit_changes(client, id, message: "Test commit") do
      assert true
    else
      message ->
        assert is_nil(message)
    end
  end

  @tag :lakefs
  test "it can add a new policy to a repository" do
    with {:ok, client} <-
           LakeFS.new("localhost",
             port: 8000,
             access_key: "AKIAIOSFOLQUICKSTART",
             secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
           ),
         {:ok, _repo} <-
           LakeFS.create_repo(client, "repo-policy", storage_namespace: "local://repo-policy"),
         {:ok, %{body: %{"id" => id}} = _policy} <-
           LakeFS.create_policy(client, LakeFS.read_policy("repo-policy")) do
      assert id != ""
    else
      message ->
        assert is_nil(message)
    end
  end

  @tag :lakefs
  test "it handles a diff event" do
    # change event to reflect a real event in your LakeFS install
    assert {:ok, _results} =
             LakeFS.diff_merge(
               %{
                 "event_type" => "pre-merge",
                 "repository_id" => "data",
                 "branch_id" => "main",
                 "source_ref" =>
                   "319ed6baf2eed9e6df8ce2525f68d419b7b3b87ddbb62a70a44e9d3c2193daf4"
               },
               fn _repo, _ref, file -> {:ok, file} end,
               fn _repo, _ref, file -> {:ok, file} end,
               fn _repo, _ref, file -> {:ok, file} end
             )
  end

  @tag :lakefs
  test "it can download a file" do
    # change to reflect a real file and ref in your LakeFS install
    assert {:ok, _body} =
             LakeFS.download_file(
               "data",
               "319ed6baf2eed9e6df8ce2525f68d419b7b3b87ddbb62a70a44e9d3c2193daf4",
               "data01.csv.m.json"
             )
  end

  @tag :lakefs
  test "it can generate a presigned url" do
    # change to reflect a real file and ref in your LakeFS install
    assert {:ok, _body} =
             LakeFS.presigned_download_url(
               System.get_env("LB_LAKEFS_URL"),
               "data",
               "main",
               "data01.csv.m.json"
             )
  end

  @tag :lakefs
  test "it can download metadata" do
    # change to reflect a real file and ref in your LakeFS install
    assert {:ok, _data} =
             LakeFS.download_metadata(
               "test",
               "Sapphire-Data-Request-by-Administrator",
               "Untitled.owx"
             )
  end
end
