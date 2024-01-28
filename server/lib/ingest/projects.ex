defmodule Ingest.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Repo

  alias Ingest.Projects.Project
  alias Ingest.Projects.ProjectMembers
  alias Ingest.Accounts.User

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
  def get_project!(id),
    do:
      Repo.get!(Project, id)
      |> Repo.preload(project_members: :project_roles)
      |> Repo.preload(:requests)

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

    Repo.one!(query)
  end

  def remove_project_member(%ProjectMembers{} = pm) do
    query =
      from p in ProjectMembers,
        where: p.member_id == ^pm.member_id and p.project_id == ^pm.project_id

    Repo.delete_all(query)
  end

  def search(search_term) do
    query =
      from(p in Project,
        where:
          fragment(
            "searchable @@ websearch_to_tsquery(?)",
            ^search_term
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(searchable, websearch_to_tsquery(?), 4)",
            ^search_term
          )
        }
      )

    Repo.all(query)
  end
end
