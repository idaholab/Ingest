defmodule Ingest.FileProcessorTest do
  use ExUnit.Case, async: true
  alias Ingest.Processors.FileProcessor

  @tag :lakefs
  test "processes a file" do
    assert {:ok, :processed} =
             FileProcessor.process("test2", "main", %{"path" => "sample3.parquet"})
  end

  @tag :lakefs
  test "deletes a file" do
    assert {:ok, _deleted} =
             FileProcessor.process_delete("test", "main", %{"path" => "Untitled.owx"})
  end

  @tag :lakefs
  test "can get metadata from a parquet file and send to datahub" do
    assert {:ok, :created} =
             FileProcessor.process_file_metadata(".parquet", "test2", "main", "sample3.parquet")
  end

  @tag :lakefs
  test "can get metadata from a csv file and send to datahub" do
    assert {:ok, :created} =
             FileProcessor.process_file_metadata(".csv", "test2", "main", "ages.csv")
  end
end
