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
alias Ingest.Uploads

{:ok, user} =
  Accounts.register_user(%{
    email: "admin@admin.com",
    password: "xxxxxxxxxxxx",
    name: "Administrator",
    roles: :admin
  })

{:ok, second_user} =
  Accounts.register_user(%{
    email: "user@user.com",
    password: "xxxxxxxxxxxx",
    name: "Normal User",
    roles: :manager
  })

{:ok, project} =
  Projects.create_project(%{
    name: "Sapphire",
    description: "A standard project",
    inserted_by: user.id
  })

{:ok, project_member} = Projects.add_user_to_project(project, second_user)
{:ok, invite} = Projects.invite(project, second_user)

# build a second project owned by the second_user so we can see how invites look
{:ok, project2} =
  Projects.create_project(%{
    name: "Emerald",
    description: "Standard project",
    inserted_by: second_user.id
  })

{:ok, template} =
  Requests.create_template(%{
    name: "Standard Questions",
    inserted_by: user.id,
    description: "Common questions about your data",
    fields: [
      %{
        label: "Name",
        help_text: "Name of the data.",
        type: :text,
        required: true,
        per_file: false,
        file_extensions: []
      },
      %{
        label: "Number of data points",
        help_text: "Whole number representing amount of data points",
        type: :number,
        required: false,
        per_file: false,
        file_extensions: [".parquet"]
      },
      %{
        label: "Location Collected",
        help_text: "Options of location of collection",
        type: :select,
        select_options: ["United States", "Canada"],
        required: false,
        per_file: true,
        file_extensions: []
      },
      %{
        label: "Secure Data",
        help_text: "Is this data considered secure?",
        type: :checkbox,
        required: false,
        per_file: false,
        file_extensions: []
      },
      %{
        label: "Date Collected",
        help_text: "When was this data collected",
        type: :date,
        required: false,
        per_file: false,
        file_extensions: []
      },
      %{
        label: "Additional Comments",
        help_text: "Make your comments here",
        type: :textarea,
        required: false,
        per_file: false,
        file_extensions: []
      }
    ]
  })

{:ok, template_2} =
  Requests.create_template(%{
    name: "Test Template 2",
    inserted_by: user.id,
    description: "A testing template, again",
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
    name: "Azure Storage Emulation",
    type: :azure,
    azure_config: %{
      account_name: "devstoreaccount1",
      # DON'T PANIC - this is a well known development key published on Microsoft's website for the Azurite emulator
      account_key:
        "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==",
      base_url: "127.0.0.1:10000/devstoreaccount1",
      ssl: false,
      container: "test"
    }
  })

{:ok, destination2} =
  Destinations.create_destination_for_user(user, %{
    name: "LakeFS Storage",
    type: :lakefs,
    lakefs_config: %{
      # DON'T PANIC - this is a well known development key published by LakeFS
      access_key_id: "AKIAIOSFOLQUICKSTART",
      # DON'T PANIC - this is a well known development key published by LakeFS
      secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
      base_url: "127.0.0.1",
      port: 8000,
      repository: "sapphire",
      ssl: false
    }
  })

{:ok, request} =
  Requests.create_request(
    %{
      name: "Sapphire Data Request",
      description: "A standard request for data",
      status: :draft,
      public: true,
      project_id: project.id
    },
    project,
    [template],
    [destination2],
    user
  )

{:ok, upload} =
  Uploads.create_upload(
    %{
      filename: "data.parquet",
      ext: "application/parquet"
    },
    request,
    user
  )

{:ok, notification} =
  Accounts.create_notifications(
    %{
      body: "Upload Requires Metadata",
      subject: "You must now submit metadata for your uploaded data."
    },
    user
  )
