defmodule Ingest.FileProcessorTest do
  use ExUnit.Case, async: true
  alias Ingest.Processors.FileProcessor

  test "processes a file correctly" do
    assert :ok = FileProcessor.process("test", "main", %{"path" => "Untitled.owx"})
  end

  test "deletes a file correctly" do
    assert {:ok, _deleted} =
             FileProcessor.process_delete("test", "main", %{"path" => "Untitled.owx"})
  end
end
