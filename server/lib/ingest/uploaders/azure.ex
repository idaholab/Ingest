defmodule Ingest.Uploaders.Azure do
  alias ExMicrosoftAzureStorage.Storage
  alias ExMicrosoftAzureStorage.Storage.{Blob, Container}

  @behaviour Phoenix.LiveView.UploadWriter

  @impl true
  def init(opts) do
    filename = Keyword.fetch!(opts, :name)
    user_id = Keyword.fetch!(opts, :user_id)

    key = "#{user_id}/#{filename}"

    {:ok, pid} =
      :erlazure.start(
        to_charlist("devstoreaccount1"),
        to_charlist(
          "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
        )
      )

    {:ok, %{chunk: 1, parts: [], pid: pid}}
  end

  @impl true
  def meta(state) do
    %{key: state.key}
  end

  @impl true
  def write_chunk(data, state) do
    dbg(data)

    dbg(
      :erlazure.put_block_blob(
        state.pid,
        to_charlist("alexandria"),
        to_charlist("test.jpg"),
        <<>>,
        url: "test"
      )
    )

    {:ok, state}
    # {:ok, %{state | chunk: state.chunk + 1, parts: [state.chunk | state.parts]}}
  end

  @impl true
  def close(state, reason) do
    {:ok, state}
  end
end
