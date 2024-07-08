defmodule Ingest.Uploads.UploadNotifier do
  @moduledoc """
  Used for sending emails with invites to the various projects you might have been
  invited to. Also controls project related information.
  """
  import Swoosh.Email

  alias Ingest.Accounts
  alias Ingest.Accounts.User
  alias Ingest.Uploads.Upload
  alias Ingest.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"DeepLynx Ingest Metadata Request", "alexandria@inl.gov"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def notify_upload_metadata(
        :notification,
        %User{} = user,
        %Upload{} = upload,
        %Ingest.Requests.Request{} = request
      ) do
    Accounts.create_notifications(
      %{
        subject:
          "You have outstanding support data requests for the #{upload.filename} you uploaded.",
        body: """

          You have an outstanding request for supporting data for a recent upload. Please navigate to the link below and enter the supporting data.

        """,
        action_link: "#{IngestWeb.Endpoint.url()}/dashboard/uploads/#{request.id}/#{upload.id}"
      },
      user
    )
  end

  def notify_upload_metadata(
        :email,
        email,
        %Upload{} = upload,
        %Ingest.Requests.Request{} = request
      ) do
    deliver(
      email,
      "You have outstanding support data requests for the #{upload.filename} you uploaded.",
      """
      ==============================

        Hi #{email},

        You have an outstanding request for supporting data for a recent upload. Please navigate to the link below and enter the supporting data.

        #{IngestWeb.Endpoint.url()}/dashboard/uploads/#{request.id}/#{upload.id}

        If you don't recognize this filename or email sender, ignore this message.

        ==============================
      """
    )
  end
end
