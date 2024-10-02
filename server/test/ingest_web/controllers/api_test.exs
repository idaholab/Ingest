defmodule IngestWeb.ApiTest do
  use IngestWeb.ConnCase, async: true

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
          hook_id: "metadata_send_trigger",
          repository_id: "no-repo",
          branch_id: "main",
          source_ref: "bad"
        })
      )

    # Assert the response and status
    assert conn.state == :sent
    assert conn.status == 500
  end

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
