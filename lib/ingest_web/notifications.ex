defmodule IngestWeb.Notifications do
  @moduledoc """
  Handles the creation of the notification in the database and then alerting the user if they're
  connected by broadcasting to the notifications channel
  """
  require Logger
  alias Ingest.Accounts
  alias Ingest.Projects.Project
  alias Ingest.Accounts.User

  def notify(:project_invite, %User{} = user, %Project{} = project) do
    save_and_notify(
      user,
      %{
        subject: "Project Invitation",
        body: "You've been invited to project #{project.name}",
        action_link: "/dashboard/projects/accept/#{project.id}"
      }
    )
  end

  defp save_and_notify(%User{} = user, notification) do
    case Accounts.create_notifications(notification, user) do
      {:ok, n} ->
        IngestWeb.Endpoint.broadcast("notifications:#{user.id}", "new_notification", %{id: n.id})

      {:error, _e} ->
        Logger.error("unable to send user notification")
    end
  end
end
