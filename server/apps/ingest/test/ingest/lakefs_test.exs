defmodule Ingest.LakeFSTest do
  @moduledoc """
  Tests for the Lakefs Module.
  """
  use ExUnit.Case, async: false
  alias Ingest.LakeFS

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
