defmodule ElixirPython.Python do
  @moduledoc """
  Manages interaction with Python processes, enabling Elixir to call Python functions.

  This module handles starting and stopping Python instances, as well as calling
  functions within specified Python modules. Python modules are expected to be located
  in the `priv/python/parsers` directory.

    * `start/0` - Starts a Python instance with a specified path.
    * `call/4` - Synchronously calls a function in a Python module.
    * `cast/2` - Sends an asynchronous message to a Python process.
    * `stop/1` - Stops a running Python instance.
  """

  def start() do
    path =
      [
        :code.priv_dir(:ingest),
        "python/parsers",
      ]
      |> Path.join()

    IO.puts("Python path: #{path}") # Debug output to confirm the path

    {:ok, pid} = :python.start([
      {:python_path, to_charlist(path)}
    ])

    pid
  end

  def call(pid, module, function, args \\ []) do
    :python.call(pid, module, function, args)
  end

  def cast(pid, message) do
    :python.cast(pid, message)
  end

  def stop(pid) do
    :python.stop(pid)
  end
end
