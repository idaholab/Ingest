defmodule Ingest.Requests.RequestNotifier do
  @moduledoc """
  Used for sending emails with invites to the various Requests you might have been
  invited to. Also controls request related information.
  """
  import Swoosh.Email

  alias Ingest.Requests.Request
  alias Ingest.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Alexandria Ingest Request Management", "Alexandria@inl.gov"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def notify_data_request_invite(email, %Request{} = request) do
    deliver(email, "You've been invited to upload to the #{request.name} data request!", """
    ==============================

      Hi #{email},

      You've received an invitation to join the #{request.name} data request. Click the link below to respond.

      #{IngestWeb.Endpoint.url()}/dashboard/uploads/#{request.id}

      If you don't recognize this request, ignore this message.

      ==============================
    """)
  end
end
