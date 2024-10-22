defmodule Ingest.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ingest.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Ingest.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a notifications.
  """
  def notifications_fixture(attrs \\ %{}) do
    {:ok, notifications} =
      attrs
      |> Enum.into(%{
        body: "some body",
        seen: true,
        subject: "some subject"
      })
      |> Ingest.Accounts.create_notifications(Ingest.AccountsFixtures.user_fixture())

    notifications
  end

  @doc """
  Generate a user_keys.
  """
  def user_keys_fixture(user, attrs \\ %{}) do
    {:ok, user_keys} =
      Ingest.Accounts.create_user_keys(
        user,
        attrs
        |> Enum.into(%{
          access_key: UUID.uuid4(:hex),
          expires: ~U[2024-10-20 14:32:00Z]
        })
      )

    user_keys
  end
end
