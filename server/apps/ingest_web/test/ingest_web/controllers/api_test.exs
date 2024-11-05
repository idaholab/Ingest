defmodule IngestWeb.ApiTest do
  use IngestWeb.ConnCase, async: false

  @tag :lakefs
  test "handle merge event from lakefs", %{conn: conn} do
    # Create a test connection
    # TODO: change the event information to match your use case
    # event does not contain all possible fields, only the ones we need
    conn =
      post(
        conn |> put_req_header("content-type", "application/json"),
        "/api/v1/merge",
        Jason.encode!(%{
          event_type: "pre-merge",
          hook_id: "metadata_send_trigger",
          repository_id: "test",
          branch_id: "main",
          source_ref: "909d8e095a33faa5f51deb359d995cb9bfd8ab02b41b0f2ca26999f0728c2a49"
        })
      )

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 200
  end

  @tag :lakefs
  test "will fail on bad event", %{conn: conn} do
    # Create a test connection
    # TODO: change the event information to match your use case
    # event does not contain all possible fields, only the ones we need
    conn =
      post(
        conn |> put_req_header("content-type", "application/json"),
        "/api/v1/merge",
        Jason.encode!(%{
          event_type: "pre-merge",
          event_time: "2024-10-02T18:52:45Z",
          action_name: "Metadata Sent to Datahub",
          hook_id: "metadata_send_trigger",
          repository_id: "test2",
          branch_id: "main",
          source_ref: "e118169f5341a890f05b127727859c166977da268dca13ff2cfde599245b127e",
          commit_id: "6ddda463ecbceab5db8fc219199282cbad8406483964ace972272a32d2d62bfb",
          commit_message: "Merge 'Test-by-John' into 'main'",
          committer: "00uc1raqm08pdOQpA4h6",
          commit_metadata: %{".lakefs.merge.strategy" => "default"}
        })
      )

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 500
  end

  @tag :lakefs
  test "handles a download link", %{conn: conn} do
    # Create a test connection
    # TODO: change to an existing URN
    conn =
      get(
        conn |> put_req_cookie("PLAY_SESSION", "REPLACE WITH COOKIE"),
        "/api/v1/download_link?urn=urn:li:dataset:(urn:li:dataPlatform:lakefs,spark-sql2.cmd,DEV)"
      )

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 302
    assert !is_nil(Plug.Conn.get_resp_header(conn, "location"))
  end
end
