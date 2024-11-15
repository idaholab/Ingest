defmodule Ingest.PythonParsers do
  @moduledoc """
  Provides functions to parse various file types by calling Python scripts via `erlport`.

  This module defines functions to parse binary, INI, MATLAB, and TDMS files by interacting
  with Python scripts located in the `priv/python/parsers` directory.

  Each function accepts a file path as an argument and returns the parsed data.
  """

  alias ElixirPython.Python

  def parse_bin(file_path) do
    pid = Python.start()
    result = Python.call(pid, :bin_parser, :parse_bin_header, [file_path])
    Python.stop(pid)
    result
  end

  def parse_ini(file_path) do
    pid = Python.start()
    result = Python.call(pid, :ini_parser, :parse_ini_file, [file_path])
    Python.stop(pid)
    result
  end

  def parse_mat(file_path) do
    pid = Python.start()
    result = Python.call(pid, :matlab_parser, :parse_mat_file, [file_path])
    Python.stop(pid)
    result
  end

  def parse_m(file_path) do
    pid = Python.start()
    result = Python.call(pid, :matlab_parser, :parse_m_file, [file_path])
    Python.stop(pid)
    result
  end

  def parse_tdms(file_path) do
    pid = Python.start()
    metadata = Python.call(pid, :tdms_parser, :parse_tdms_metadata, [file_path])
    Python.stop(pid)
    metadata
  end
end
