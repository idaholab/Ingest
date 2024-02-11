defmodule Ingest.Projects.ProjectNotifier do
  @moduledoc """
  Used for sending emails with invites to the various projects you might have been
  invited to. Also controls project related information.
  """
  import Swoosh.Email

  alias Ingest.Projects.Project
  alias Ingest.Accounts.User
  alias Ingest.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"DeepLynx Ingest Project Management", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_project_invite(email, %Project{} = project) do
    IngestWeb.Endpoint.url()

    deliver(email, "You've been invited to the #{project.name} project!", """
    ==============================

      Hi #{email},

      You've received an invitation to join the #{project.name} project. Click the link below to respond.

      #{IngestWeb.Endpoint.url()}/dashboard/projects/accept/#{project.id}

      If you don't recognize this project, ignore this message.

      ==============================
    """)
  end
end
