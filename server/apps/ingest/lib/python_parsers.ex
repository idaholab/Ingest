defmodule Ingest.PythonParsers do
  @moduledoc """
  Provides functions for sending files to the Python parser to handle different file types.
  
  This module sends the file to Pythons `main.process_file`, which determines the file type
  and uses the correct parser based on the file extension.
  """

  alias ElixirPython.Python

  def process_file(file_path) do
    pid = Python.start()
    result = Python.call(pid, :main, :process_file, [file_path])
    Python.stop(pid)
    result
  end
end
