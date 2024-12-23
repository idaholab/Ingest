defmodule Ingest.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Projects.ProjectDestination
  alias Ingest.Projects.ProjectSearch
  alias Ingest.Repo

  alias Ingest.Projects.Project
  alias Ingest.Projects.ProjectMembers
  alias Ingest.Accounts.User
  alias Ingest.Requests.Template

  @doc """
  Returns the list of project.

  ## Examples

      iex> list_project()
      [%Project{}, ...]

  """
  def list_project do
    Repo.all(Project)
    |> Repo.preload([:project_members, :requests])
  end

  # we want the raw object for the additional encoded data
  def list_project_members(%Project{} = project) do
    Repo.all(from pm in ProjectMembers, where: pm.project_id == ^project.id)
    |> Repo.preload(:user)
  end

  def update_project_members(%Project{} = project, %User{} = user, role) do
    from(pm in ProjectMembers,
      where:
        pm.member_id ==
          ^user.id and pm.project_id == ^project.id
    )
    |> Repo.update_all(set: [role: role])
  end

  def list_project_with_count do
    query =
      from p in Project,
        left_join: r in assoc(p, :requests),
        group_by: p.id,
        select: {p, count(r.id)}

    Repo.all(query)
  end

  @doc """
  List your own projects, either as owner or member, and the count of requests for each
  """
  def list_own_projects_with_count(user_id) do
    query =
      from p in Project,
        left_join: pm in assoc(p, :project_members),
        left_join: r in assoc(p, :requests),
        where: pm.id == ^user_id or p.inserted_by == ^user_id,
        group_by: p.id,
        select: {p, count(r.id)}

    Repo.all(query)
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id) do
    Repo.get!(Project, id)
    |> Repo.preload(:user)
    |> Repo.preload(project_members: :project_roles)
    |> Repo.preload(invites: :invited_user)
    |> Repo.preload(:requests)
    |> Repo.preload(:templates)
    |> Repo.preload(:destinations)
  end

  def get_owned_project!(%User{} = user, id) do
    Repo.one!(
      from p in Project,
        left_join: pm in assoc(p, :project_members),
        left_join: r in assoc(p, :requests),
        where: (pm.id == ^user.id or p.inserted_by == ^user.id) and p.id == ^id,
        group_by: p.id,
        preload: [
          :user,
          :requests,
          :templates,
          :destinations,
          invites: :invited_user,
          project_members: :project_roles
        ],
        select: p
    )
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  def add_user_to_project(%Project{} = project, %User{} = user, role \\ :member) do
    %ProjectMembers{}
    |> ProjectMembers.changeset(%{member_id: user.id, project_id: project.id, role: role})
    |> Repo.insert()
  end

  def get_member_project(member_id, project_id) do
    query =
      from pm in ProjectMembers,
        where: pm.member_id == ^member_id and pm.project_id == ^project_id

    Repo.one(query)
  end

  def remove_project_member(%ProjectMembers{} = pm) do
    query =
      from p in ProjectMembers,
        where: p.member_id == ^pm.member_id and p.project_id == ^pm.project_id

    Repo.delete_all(query)
  end

  @defaults %{exclude: []}
  def search(search_term, opts \\ []) do
    %{exclude: exclude} = Enum.into(opts, @defaults)

    query =
      from ps in ProjectSearch,
        join: p in Project,
        on: ps.id == p.id,
        where:
          fragment("projects_search MATCH ?", ^search_term) and
            p.id not in ^Enum.map(exclude, fn p -> p.id end),
        order_by: [asc: :rank],
        select: p

    Repo.all(query)
  end

  alias Ingest.Projects.ProjectInvites

  @doc """
  Returns the list of project_invites.

  ## Examples

      iex> list_project_invites()
      [%ProjectInvites{}, ...]

  """
  def list_project_invites(%Project{} = project) do
    Repo.all(from p in ProjectInvites, where: p.project_id == ^project.id)
  end

  def list_project_invites_user(%Project{} = project, %User{} = user) do
    Repo.all(
      from p in ProjectInvites, where: p.project_id == ^project.id and p.email == ^user.email
    )
  end

  @doc """
  Gets a single project_invites.

  Raises `Ecto.NoResultsError` if the Project invites does not exist.

  ## Examples

      iex> get_project_invites!(123)
      %ProjectInvites{}

      iex> get_project_invites!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project_invites!(id), do: Repo.get!(ProjectInvites, id)

  @doc """
  Creates a project_invites.

  ## Examples

      iex> create_project_invites(%{field: value})
      {:ok, %ProjectInvites{}}

      iex> create_project_invites(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project_invites(attrs \\ %{}) do
    %ProjectInvites{}
    |> ProjectInvites.changeset(attrs)
    |> Repo.insert()
  end

  def invite(%Project{} = project, %User{} = user) do
    %ProjectInvites{}
    |> ProjectInvites.changeset(%{email: user.email})
    |> Ecto.Changeset.put_assoc(:project, project)
    |> Ecto.Changeset.put_assoc(:invited_user, user)
    |> Repo.insert()
  end

  def invite_by_email(%Project{} = project, email) do
    %ProjectInvites{}
    |> ProjectInvites.email_changeset(%{email: email})
    |> Ecto.Changeset.put_assoc(:project, project)
    |> Repo.insert()
  end

  @doc """
  Updates a project_invites.

  ## Examples

      iex> update_project_invites(project_invites, %{field: new_value})
      {:ok, %ProjectInvites{}}

      iex> update_project_invites(project_invites, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project_invites(%ProjectInvites{} = project_invites, attrs) do
    project_invites
    |> ProjectInvites.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project_invites.

  ## Examples

      iex> delete_project_invites(project_invites)
      {:ok, %ProjectInvites{}}

      iex> delete_project_invites(project_invites)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project_invites(%ProjectInvites{} = project_invites) do
    Repo.delete(project_invites)
  end

  def delete_all_invites(%Project{} = project, %User{} = user) do
    Repo.delete_all(
      from i in ProjectInvites,
        where: i.project_id == ^project.id and i.email == ^user.email
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project_invites changes.

  ## Examples

      iex> change_project_invites(project_invites)
      %Ecto.Changeset{data: %ProjectInvites{}}

  """
  def change_project_invites(%ProjectInvites{} = project_invites, attrs \\ %{}) do
    ProjectInvites.changeset(project_invites, attrs)
  end

  def get_template!(id), do: Repo.get!(Template, id)

  def update_project_templates(%Project{} = request, templates) do
    request
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:templates, templates)
    |> Repo.update()
  end

  def update_project_destinations(%Project{} = request, destinations) do
    request
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:destinations, destinations)
    |> Repo.update()
  end

  def update_project_destination_config(
        %Ingest.Destinations.DestinationMembers{} = member,
        config
      ) do
    from(pd in ProjectDestination,
      where:
        pd.project_id == ^member.project_id and
          pd.destination_id == ^member.destination_id
    )
    |> Repo.update_all(set: [additional_config: config])
  end

  def add_destination(%Project{} = project, destination) do
    %ProjectDestination{
      project_id: project.id,
      destination_id: destination.id
    }
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_destination(%Project{} = project, destination) do
    Repo.delete_all(
      from d in "project_destinations",
        where:
          d.project_id == type(^project.id, :binary_id) and
            d.destination_id == type(^destination.id, :binary_id)
    )
  end

  # this is needed so we can get the additional configuration on the
  # destination
  def get_project_destination(%Project{} = project, destination) do
    # there should only ever be _one_ destination/project combination
    Repo.one(
      from pd in ProjectDestination,
        where: pd.project_id == ^project.id and pd.destination_id == ^destination.id,
        select: pd
    )
    |> Repo.preload(project: [:destinations])
  end

  def remove_template(%Project{} = project, template) do
    Repo.delete_all(
      from d in "project_templates",
        where:
          d.project_id == type(^project.id, :binary_id) and
            d.template_id == type(^template.id, :binary_id)
    )
  end

  def request_count(%Project{} = project) do
    Repo.all(
      from r in "requests",
        where: r.project_id == type(^project.id, :binary_id),
        select: count()
    )
  end
end
