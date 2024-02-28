defmodule Ingest.Uploaders.Azure do
  @behaviour Phoenix.LiveView.UploadWriter

  @impl true
  def init(opts) do
    filename = Keyword.fetch!(opts, :name)
    user_id = Keyword.fetch!(opts, :user_id)

    _key = "#{user_id}/#{filename}"

    {:ok, %{chunk: 1, parts: []}}
  end

  @impl true
  def meta(state) do
    %{key: state.key}
  end

  @impl true
  def write_chunk(_data, state) do
    {:ok, state}
    # {:ok, %{state | chunk: state.chunk + 1, parts: [state.chunk | state.parts]}}
  end

  @impl true
  def close(state, _reason) do
    {:ok, state}
  end
end
