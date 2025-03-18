defmodule Ingest.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Repo

  alias Ingest.Accounts.{User, UserToken, UserNotifier, Notifications}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def delete_user!(%User{} = user) do
    Repo.delete!(user)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def register_user(attrs, :oidcc) do
    %User{}
    |> User.oidcc_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  def update_user_identity_provider(user, attrs \\ %{}) do
    User.identity_provider_changeset(user, attrs)
    |> Repo.update()
  end

  def user_edit_change(%User{} = user, attrs \\ %{}) do
    User.edit_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def update_user(%User{} = user, attrs \\ %{}) do
    user
    |> User.edit_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction(mode: :immediate)
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def list_users do
    Repo.all(User)
  end

  alias Ingest.Accounts.Notifications

  @doc """
  Returns the list of notifications.

  ## Examples

      iex> list_notifications()
      [%Notifications{}, ...]

  """
  def list_notifications do
    Repo.all(Notifications)
  end

  def list_own_notifications(%User{} = user) do
    Repo.all(from n in Notifications, where: n.user_id == ^user.id, limit: 10)
  end

  @doc """
  Gets a single notifications.

  Raises `Ecto.NoResultsError` if the Notifications does not exist.

  ## Examples

      iex> get_notifications!(123)
      %Notifications{}

      iex> get_notifications!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notifications!(id), do: Repo.get!(Notifications, id)

  @doc """
  Creates a notifications.

  ## Examples

      iex> create_notifications(%{field: value})
      {:ok, %Notifications{}}

      iex> create_notifications(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notifications(attrs \\ %{}, %User{} = user) do
    %Notifications{}
    |> Notifications.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a notifications.

  ## Examples

      iex> update_notifications(notifications, %{field: new_value})
      {:ok, %Notifications{}}

      iex> update_notifications(notifications, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notifications(%Notifications{} = notifications, attrs) do
    notifications
    |> Notifications.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a notifications.

  ## Examples

      iex> delete_notifications(notifications)
      {:ok, %Notifications{}}

      iex> delete_notifications(notifications)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notifications(%Notifications{} = notifications) do
    Repo.delete(notifications)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notifications changes.

  ## Examples

      iex> change_notifications(notifications)
      %Ecto.Changeset{data: %Notifications{}}

  """
  def change_notifications(%Notifications{} = notifications, attrs \\ %{}) do
    Notifications.changeset(notifications, attrs)
  end

  alias Ingest.Accounts.UserKeys

  @doc """
  Returns the list of user_keys.

  ## Examples

      iex> list_user_keys()
      [%UserKeys{}, ...]

  """
  def list_user_keys do
    Repo.all(UserKeys)
  end

  def list_user_keys(%User{} = user) do
    Repo.all(from u in UserKeys, where: u.user_id == ^user.id)
  end

  @doc """
  Gets a single user_keys.

  Raises `Ecto.NoResultsError` if the User keys does not exist.

  ## Examples

      iex> get_user_keys!(123)
      %UserKeys{}

      iex> get_user_keys!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_keys!(id), do: Repo.get!(UserKeys, id)

  def get_user_key!(%User{} = user, key),
    do: Repo.one!(from u in UserKeys, where: u.access_key == ^key and u.user_id == ^user.id)

  @doc """
  Creates a user_keys.

  ## Examples

      iex> create_user_keys(%{field: value})
      {:ok, %UserKeys{}}

      iex> create_user_keys(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_keys(%User{} = user, attrs \\ %{}) do
    %UserKeys{user_id: user.id}
    |> UserKeys.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user_keys.

  ## Examples

      iex> update_user_keys(user_keys, %{field: new_value})
      {:ok, %UserKeys{}}

      iex> update_user_keys(user_keys, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_keys(%UserKeys{} = user_keys, attrs) do
    user_keys
    |> UserKeys.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user_keys.

  ## Examples

      iex> delete_user_keys(user_keys)
      {:ok, %UserKeys{}}

      iex> delete_user_keys(user_keys)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user_keys(%UserKeys{} = user_keys) do
    Repo.delete(user_keys)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user_keys changes.

  ## Examples

      iex> change_user_keys(user_keys)
      %Ecto.Changeset{data: %UserKeys{}}

  """
  def change_user_keys(%UserKeys{} = user_keys, attrs \\ %{}) do
    UserKeys.changeset(user_keys, attrs)
  end
end
