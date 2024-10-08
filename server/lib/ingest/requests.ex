defmodule Ingest.Requests do
  @moduledoc """
  The Requests context.
  """

  import Ecto.Query, warn: false
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
    Repo.all(from(t in Template, where: t.inserted_by == ^user.id))
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
  def get_template!(id), do: Repo.get!(Template, id)

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

  def is_invited(%User{} = user) do
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
        from t in Template,
          where:
            fragment(
              "searchable @@ to_tsquery(concat(regexp_replace(trim(?), '\W+', ':* & '), ':*'))",
              ^search_term
            ) and t.id not in ^Enum.map(exclude, fn d -> d.id end),
          order_by: {
            :desc,
            fragment(
              "ts_rank_cd(searchable, to_tsquery(concat(regexp_replace(trim(?), '\W+', ':* & '), ':*')), 4)",
              ^search_term
            )
          }

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
        from t in Template,
          where:
            fragment(
              "searchable @@ to_tsquery(concat(regexp_replace(trim(?), '\W+', ':* & '), ':*'))",
              ^search_term
            ) and t.id not in ^Enum.map(exclude, fn d -> d.id end) and t.inserted_by == ^user.id,
          order_by: {
            :desc,
            fragment(
              "ts_rank_cd(searchable, to_tsquery(concat(regexp_replace(trim(?), '\W+', ':* & '), ':*')), 4)",
              ^search_term
            )
          }

      Repo.all(query)
    end
  end

  def search_requests_by_project(search_term) do
    if search_term == "" do
      []
    else
      search_term = String.replace(search_term, " ", "")

      Repo.all(
        from(r in Request,
          join: p in Project,
          on: p.id == r.project_id,
          where:
            fragment(
              "p1.searchable @@ to_tsquery(concat(regexp_replace(trim(?), '\W+', ':* & '), ':*'))",
              ^search_term
            ) and r.status == :published,
          order_by: {
            :desc,
            fragment(
              "ts_rank_cd(p1.searchable, to_tsquery(concat(regexp_replace(trim(?), '\W+', ':* & '), ':*')), 4)",
              ^search_term
            )
          }
        )
      )
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
end
