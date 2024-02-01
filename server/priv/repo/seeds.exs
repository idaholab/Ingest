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
alias Ingest.Destinations

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
    inserted_by: user.id,
    description: "A testing template",
    fields: [
      %{
        label: "Text Field",
        help_text: "This is a testing field for testing purposes.",
        type: :text,
        required: true,
        per_file: false,
        file_extensions: []
      },
      %{
        label: "Number Field",
        help_text: "This is a testing field for testing purposes.",
        type: :number,
        required: false,
        per_file: false,
        file_extensions: [".pdf", ".xls"]
      },
      %{
        label: "Select Field",
        help_text: "This is a testing field for testing purposes.",
        type: :select,
        select_options: ["option 1", "option 2"],
        required: false,
        per_file: true,
        file_extensions: []
      },
      %{
        label: "Checkbox Field",
        help_text: "This is a testing field for testing purposes.",
        type: :checkbox,
        required: false,
        per_file: false,
        file_extensions: []
      },
      %{
        label: "Date Field",
        help_text: "This is a testing field for testing purposes.",
        type: :date,
        required: false,
        per_file: false,
        file_extensions: []
      },
      %{
        label: "Text Area Field",
        help_text: "This is a testing field for testing purposes.",
        type: :textarea,
        required: false,
        per_file: false,
        file_extensions: []
      }
    ]
  })

{:ok, destination} =
  Destinations.create_destination_for_user(user, %{
    name: "Test Destination",
    type: :passive
  })

{:ok, request} =
  Requests.create_request(
    %{
      name: "Test Request",
      description: "A testing request",
      status: :draft,
      public: true,
      project_id: project.id
    },
    project,
    [template],
    [destination],
    user
  )
