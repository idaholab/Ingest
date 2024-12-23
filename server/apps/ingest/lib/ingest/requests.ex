defmodule Ingest.Requests do
  @moduledoc """
  The Requests context.
  """

  import Ecto.Query, warn: false
  alias Ingest.Requests.RequestDestination
  alias Ingest.Projects.ProjectSearch
  alias Ingest.Requests.TemplateSearch
  alias Ingest.Uploads.Upload
  alias Ingest.Requests.TemplateField
  alias Ingest.Accounts.User
  alias Ingest.Projects.Project
  alias Ingest.Repo
  alias Ingest.Destinations.Destination
  alias Ingest.Requests.RequestMembers

  alias Ingest.Requests.Template

  @doc """
  Returns the list of templates.

  ## Examples

      iex> list_templates()
      [%Template{}, ...]

  """
  def list_templates do
    Repo.all(Template)
  end

  def list_own_templates(%User{} = user) do
    Repo.all(
      from(t in Template,
        left_join: tm in assoc(t, :template_members),
        where: t.inserted_by == ^user.id or tm.email == ^user.email or tm.id == ^user.id
      )
    )
  end

  @doc """
  Gets a single template.

  Raises `Ecto.NoResultsError` if the Template does not exist.

  ## Examples

      iex> get_template!(123)
      %Template{}

      iex> get_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template!(id), do: Repo.get!(Template, id) |> Repo.preload(:template_members)

  @doc """
  Creates a template.

  ## Examples

      iex> create_template(%{field: value})
      {:ok, %Template{}}

      iex> create_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template(attrs \\ %{}) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template.

  ## Examples

      iex> update_template(template, %{field: new_value})
      {:ok, %Template{}}

      iex> update_template(template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template(%Template{} = template, attrs) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a template.

  ## Examples

      iex> delete_template(template)
      {:ok, %Template{}}

      iex> delete_template(template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template(%Template{} = template) do
    Repo.delete(template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template changes.

  ## Examples

      iex> change_template(template)
      %Ecto.Changeset{data: %Template{}}

  """
  def change_template(%Template{} = template, attrs \\ %{}) do
    Template.changeset(template, attrs)
  end

  def change_template_field(%TemplateField{} = field, attrs \\ %{}) do
    TemplateField.changeset(field, attrs)
  end

  alias Ingest.Requests.Request

  @doc """
  Returns the list of requests.

  ## Examples

      iex> list_requests()
      [%Request{}, ...]

  """
  def list_requests do
    Repo.all(Request)
  end

  def list_own_requests(%User{} = user) do
    Repo.all(from(r in Request, where: r.inserted_by == ^user.id)) |> Repo.preload(:project)
  end

  def list_invited_request(%User{} = user) do
    Repo.all(
      from(r in Request,
        join: m in RequestMembers,
        on: r.id == m.request_id,
        where: ^user.email == m.email and r.status == :published
      )
    )
    |> Repo.preload(:project)
  end

  def invited?(%User{} = user) do
    request_for_creator =
      Repo.all(
        from r in Request,
          where: ^user.id == r.inserted_by
      )

    request_for_invited =
      Repo.one(
        from r in Request,
          join: m in RequestMembers,
          on: r.id == m.request_id,
          where: ^user.email == m.email
      )

    request_for_creator == nil and request_for_invited == nil
  end

  @doc """
  Gets a single request.

  Raises `Ecto.NoResultsError` if the Request does not exist.

  ## Examples

      iex> get_request!(123)
      %Request{}

      iex> get_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_request!(id),
    do:
      Repo.get!(Request, id)
      |> Repo.preload(:templates)
      |> Repo.preload(project: [:templates, :destinations])
      |> Repo.preload(:destinations)

  @doc """
  Creates a request.

  ## Examples

      iex> create_request(%{field: value})
      {:ok, %Request{}}

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request(attrs \\ %{}) do
    %Request{}
    |> Request.changeset(attrs)
    |> Repo.insert()
  end

  def create_request(
        attrs \\ %{},
        %Project{} = project,
        [%Template{}] = templates,
        [%Destination{}] = destinations,
        %User{} = user
      ) do
    %Request{}
    |> Request.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:project, project)
    |> Ecto.Changeset.put_assoc(:templates, templates)
    |> Ecto.Changeset.put_assoc(:destinations, destinations)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a request.

  ## Examples

      iex> update_request(request, %{field: new_value})
      {:ok, %Request{}}

      iex> update_request(request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_request(%Request{} = request, attrs) do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a request.

  ## Examples

      iex> delete_request(request)
      {:ok, %Request{}}

      iex> delete_request(request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_request(%Request{} = request) do
    Repo.delete(request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking request changes.

  ## Examples

      iex> change_request(request)
      %Ecto.Changeset{data: %Request{}}

  """
  def change_request(%Request{} = request, attrs \\ %{}) do
    Request.changeset(request, attrs)
  end

  def get_request_destination(%Request{} = request, destination) do
    # there should only ever be _one_ destination/request combination
    Repo.one(
      from rd in Ingest.Requests.RequestDestination,
        where: rd.request_id == ^request.id and rd.destination_id == ^destination.id,
        select: rd
    )
    |> Repo.preload(request: [:destinations])
  end

  def remove_destination(%Request{} = request, %Destination{} = destination) do
    Repo.delete_all(
      from(d in "request_destinations",
        where:
          d.destination_id == type(^destination.id, :binary_id) and
            d.request_id == type(^request.id, :binary_id)
      )
    )
  end

  def remove_template(%Request{} = request, %Template{} = template) do
    Repo.delete_all(
      from(d in "request_templates",
        where:
          d.template_id == type(^template.id, :binary_id) and
            d.request_id == type(^request.id, :binary_id)
      )
    )
  end

  def update_request_project(%Request{} = request, %Project{} = project) do
    request
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:project, project)
    |> Repo.update()
  end

  def update_request_templates(%Request{} = request, templates) do
    request
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:templates, templates)
    |> Repo.update()
  end

  def update_request_destinations(%Request{} = request, destinations) do
    request
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:destinations, destinations)
    |> Repo.update()
  end

  def list_recent_requests(%User{} = user) do
    Repo.all(
      from(r in Request,
        join: u in Upload,
        on: u.request_id == r.id,
        where: r.inserted_by == ^user.id and r.status == :published,
        group_by: r.id,
        limit: 50,
        select: r
      )
    )
    |> Repo.preload(:project)
  end

  @defaults %{exclude: []}
  def search_templates(search_term, opts \\ []) do
    if search_term == "" do
      []
    else
      search_term = String.replace(search_term, " ", "")
      %{exclude: exclude} = Enum.into(opts, @defaults)

      query =
        from ts in TemplateSearch,
          join: t in Template,
          on: ts.id == t.id,
          where:
            fragment("templates_search MATCH ?", ^search_term) and
              t.id not in ^Enum.map(exclude, fn t -> t.id end),
          select: t

      Repo.all(query)
    end
  end

  @defaults %{exclude: []}
  def search_own_templates(search_term, %User{} = user, opts \\ []) do
    if search_term == "" do
      []
    else
      search_term = String.replace(search_term, " ", "")
      %{exclude: exclude} = Enum.into(opts, @defaults)

      query =
        from ts in TemplateSearch,
          join: t in Template,
          on: ts.id == t.id,
          left_join: tm in assoc(t, :template_members),
          where:
            fragment("templates_search MATCH ?", ^search_term) and
              t.id not in ^Enum.map(exclude, fn t -> t.id end) and
              (t.inserted_by == ^user.id or tm.email == ^user.email or tm.id == ^user.id),
          select: t

      Repo.all(query)
    end
  end

  def add_request_destination(
        %Request{} = request,
        %Ingest.Destinations.Destination{} = destination
      ) do
    %RequestDestination{
      request_id: request.id,
      destination_id: destination.id
    }
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_request_destination(
        %Request{} = request,
        %Ingest.Destinations.Destination{} = destination
      ) do
    Repo.delete_all(
      from rd in RequestDestination,
        where: rd.request_id == ^request.id and rd.destination_id == ^destination.id
    )
  end

  def search_requests_by_project(search_term) do
    if search_term == "" do
      []
    else
      search_term = String.replace(search_term, " ", "")

      query =
        from r in Request,
          join: p in Project,
          on: p.id == r.project_id,
          join: ps in ProjectSearch,
          on: ps.id == p.id,
          where:
            fragment("projects_search MATCH ?", ^search_term) and r.status == :published and
              r.visibility == :public,
          select: r

      Repo.all(query)
      |> Repo.preload(:project)
    end
  end

  def invite_user_by_email(%Request{} = request, email) do
    %RequestMembers{}
    |> RequestMembers.email_changeset(%{email: email})
    |> Ecto.Changeset.put_assoc(:request, request)
    |> Repo.insert()
  end

  def delete_user(%Request{} = request, email) do
    Repo.delete_all(
      from(d in "request_members",
        where: d.request_id == type(^request.id, :binary_id) and d.email == ^email
      )
    )
  end

  alias Ingest.Requests.TemplateMembers

  def check_owned_template!(%User{} = user, id) do
    Repo.one!(
      from tm in TemplateMembers,
        where: (tm.user_id == ^user.id or tm.email == ^user.email) and tm.template_id == ^id,
        select: tm
    )
  end

  def list_owned_templates(%User{} = user) do
    Repo.all(
      from t in Template,
        left_join: tm in assoc(t, :template_members),
        where: tm.id == ^user.id or tm.email == ^user.email or t.inserted_by == ^user.id,
        group_by: t.id,
        select: t
    )
  end

  def add_user_to_template(%Template{} = template, %User{} = user, role \\ :member) do
    %TemplateMembers{}
    |> TemplateMembers.changeset(%{user_id: user.id, template_id: template.id, role: role})
    |> Repo.insert()
  end

  def add_user_to_template_by_email(%Template{} = template, email, role \\ :member) do
    member = Ingest.Accounts.get_user_by_email(email)

    if member do
      %TemplateMembers{}
      |> TemplateMembers.changeset(%{
        email: email,
        user_id: member.id,
        template_id: template.id,
        role: role
      })
      |> Repo.insert()
    else
      %TemplateMembers{}
      |> TemplateMembers.changeset(%{email: email, template_id: template.id, role: role})
      |> Repo.insert()
    end
  end

  def backfill_shared_templates(%User{} = user) do
    from(tm in TemplateMembers,
      where:
        tm.email ==
          ^user.email
    )
    |> Repo.update_all(set: [user_id: user.id])
  end

  def get_user_template(member_id, template_id) do
    query =
      from tm in TemplateMembers,
        where: tm.member_id == ^member_id and tm.template_id == ^template_id

    Repo.one!(query)
  end

  def remove_template_user(%TemplateMembers{} = tm) do
    query =
      from t in TemplateMembers,
        where: t.user_id == ^tm.user_id and t.project_id == ^tm.template_id

    Repo.delete_all(query)
  end

  @doc """
  Returns the list of template_members.

  ## Examples

      iex> list_template_members()
      [%TemplateMembers{}, ...]

  """
  def list_template_members do
    Repo.all(TemplateMembers)
  end

  @doc """
  Creates a template_members.

  ## Examples

      iex> create_template_members(%{field: value})
      {:ok, %TemplateMembers{}}

      iex> create_template_members(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_template_members(attrs \\ %{}) do
    %TemplateMembers{}
    |> TemplateMembers.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a template_members.

  ## Examples

      iex> update_template_members(template_members, %{field: new_value})
      {:ok, %TemplateMembers{}}

      iex> update_template_members(template_members, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_template_members(%Template{} = template, %User{} = user, role) do
    from(tm in TemplateMembers,
      where:
        tm.user_id ==
          ^user.id and tm.template_id == ^template.id
    )
    |> Repo.update_all(set: [role: role])
  end

  def update_request_destination_config(
        %Ingest.Destinations.DestinationMembers{} = member,
        config
      ) do
    from(rd in RequestDestination,
      where:
        rd.request_id == ^member.request_id and
          rd.destination_id == ^member.destination.id
    )
    |> Repo.update_all(set: [additional_config: config])
  end

  @doc """
  Deletes a template_members.

  ## Examples

      iex> delete_template_members(template_members)
      {:ok, %TemplateMembers{}}

      iex> delete_template_members(template_members)
      {:error, %Ecto.Changeset{}}

  """
  def delete_template_members(%TemplateMembers{} = template_members) do
    Repo.delete(template_members)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking template_members changes.

  ## Examples

      iex> change_template_members(template_members)
      %Ecto.Changeset{data: %TemplateMembers{}}

  """
  def change_template_members(%TemplateMembers{} = template_members, attrs \\ %{}) do
    TemplateMembers.changeset(template_members, attrs)
  end
end
