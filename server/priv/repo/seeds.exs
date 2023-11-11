# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ingest.Repo.insert!(%Ingest.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Ingest.Accounts
alias Ingest.Projects
alias Ingest.Requests

{:ok, user} =
  Accounts.register_user(%{
    email: "admin@admin.com",
    password: "xxxxxxxxxxxx",
    name: "Administrator"
  })

{:ok, second_user} =
  Accounts.register_user(%{email: "user@user.com", password: "xxxxxxxxxxxx", name: "Normal User"})

{:ok, project} =
  Projects.create_project(%{
    name: "Test Project",
    description: "A testing project",
    inserted_by: user.id
  })

{:ok, project_member} = Projects.add_user_to_project(project, second_user)

{:ok, template} =
  Requests.create_template(%{
    name: "Test Template",
    description: "A testing template",
    structure: %{field: "test"}
  })

{:ok, request} =
  Requests.create_request(
    %{
      name: "Test Request",
      description: "A testing request",
      status: :draft,
      public: true
    },
    template,
    project,
    user
  )
