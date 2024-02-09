defmodule Ingest.Projects.ProjectNotifier do
  @moduledoc """
  Used for sending emails with invites to the various projects you might have been
  invited to. Also controls project related information.
  """
  import Swoosh.Email

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
end
