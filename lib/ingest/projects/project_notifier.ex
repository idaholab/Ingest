defmodule Ingest.Projects.ProjectNotifier do
  @moduledoc """
  Used for sending emails with invites to the various projects you might have been
  invited to. Also controls project related information.
  """
  import Swoosh.Email

  alias Ingest.Projects.Project
  alias Ingest.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Alexandria Ingest Project Management", "Alexandria@inl.gov"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def notify_project_invite(email, %Project{} = project, endpoint) do
    deliver(email, "You've been invited to the #{project.name} project!", """
    ==============================

      Hi #{email},

      You've received an invitation to join the #{project.name} project. Click the link below to respond.

      #{endpoint}/dashboard/projects/accept/#{project.id}

      If you don't recognize this project, ignore this message.

      ==============================
    """)
  end
end
