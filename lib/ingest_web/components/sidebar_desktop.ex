defmodule Sidebar do
  use IngestWeb, :html

  def desktop(assigns) do
    ~H"""
    <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-gray-900 px-6 pb-4">
        <div class="flex h-16 shrink-0 items-center mt-10 ">
          <img class="h-13 w-auto " src="/images/logo.png" alt="Your Company" />
        </div>
        <nav class="flex flex-1 flex-col mt-10">
          <ul role="list" class="flex flex-1 flex-col gap-y-7">
            <li>
              <ul role="list" class="-mx-2 space-y-1">
                <li>
                  <a href={~p"/dashboard"} class={active("dashboard", @section)}>
                    <svg
                      class="h-6 w-6 shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
                      />
                    </svg>
                    Dashboard
                  </a>
                </li>
                <li>
                  <a href={~p"/dashboard/uploads"} class={active("uploads", @section)}>
                    <.icon name="hero-arrow-up-on-square-stack" class="h-6 w-6 shrink-0" />
                    Upload Data
                  </a>
                </li>
                <li>
                  <a
                    href={~p"/dashboard/tasks"}
                    class={active("tasks", @section)}
                    let={count = tasks_count(@current_user)}
                  >
                    <.icon name="hero-clipboard-document-list" class="h-6 w-6 shrink-0" /> Tasks
                    <span
                      :if={count > 0}
                      class="inline-flex items-center gap-x-1.5 rounded-md bg-blue-100 px-2 py-1 text-xs font-medium text-blue-700"
                    >
                      <svg class="h-1.5 w-1.5 fill-blue-500" viewBox="0 0 6 6" aria-hidden="true">
                        <circle cx="3" cy="3" r="3" />
                      </svg>
                      {count}
                    </span>
                  </a>
                </li>
                <div :if={@current_user.roles in [:manager, :admin]}>
                  <li class="pt-10">
                    <div class="text-xs font-semibold leading-6 text-gray-400">Management</div>
                    <a href={~p"/dashboard/requests"} class={active("requests", @section)}>
                      <.icon name="hero-clipboard-document-check" class="h-6 w-6 shrink-0" />
                      Data Requests
                    </a>
                  </li>
                  <li>
                    <a href={~p"/dashboard/templates"} class={active("templates", @section)}>
                      <svg
                        class="h-6 w-6 shrink-0"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z"
                        />
                      </svg>
                      Metadata Collection Forms
                    </a>
                  </li>
                  <li>
                    <a href={~p"/dashboard/destinations"} class={active("destinations", @section)}>
                      <.icon name="hero-circle-stack" class="h-6 w-6 shrink-0" /> Data Destinations
                    </a>
                  </li>
                </div>
              </ul>
            </li>
            <li>
              <div class="text-xs font-semibold leading-6 text-gray-400">Your projects</div>
              <ul role="list" class="-mx-2 mt-2 space-y-1">
                <%= for {project, _count} <- projects_list(@current_user) do %>
                  <%= if @current_user.roles in [:member] do %>
                    <li>
                      <!-- Current: "bg-gray-800 text-white", Default: "text-gray-400 hover:text-white hover:bg-gray-800" -->
                      <a
                        href={~p"/dashboard/member/projects/#{project.id}"}
                        class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                      >
                        <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                          {String.at(project.name, 0)}
                        </span>
                        <span class="truncate">{project.name}</span>
                      </a>
                    </li>
                  <% else %>
                    <li>
                      <!-- Current: "bg-gray-800 text-white", Default: "text-gray-400 hover:text-white hover:bg-gray-800" -->
                      <a
                        href={~p"/dashboard/projects/#{project.id}"}
                        class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                      >
                        <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                          {String.at(project.name, 0)}
                        </span>
                        <span class="truncate">{project.name}</span>
                      </a>
                    </li>
                  <% end %>
                <% end %>
                <%= if @current_user.roles in [:member] do %>
                  <li>
                    <a
                      href="/dashboard/member/projects"
                      class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                    >
                      <.icon name="hero-plus" />
                      <span class="truncate">More Projects</span>
                    </a>
                  </li>
                <% else %>
                  <li>
                    <a
                      href="/dashboard/projects"
                      class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                    >
                      <.icon name="hero-plus" />
                      <span class="truncate">Find Projects</span>
                    </a>
                  </li>
                <% end %>
              </ul>
            </li>
            <li class="mt-auto">
              <a href={~p"/wiki"} class={active("Wiki", @section)}>
                <.icon name="hero-document" /> Wiki
              </a>
              <a href={~p"/users/settings"} class={active("settings", @section)}>
                <svg
                  class="h-6 w-6 shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                Settings
              </a>
              <a
                href="mailto:Alexandria@inl.gov"
                class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
              >
                <.icon name="hero-bug-ant" class="bg-gray-400" /> Found a bug?
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </div>
    """
  end

  def mobile(assigns) do
    ~H"""
    <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-gray-900 px-6 pb-4 ring-1 ring-white/10">
      <div class="flex h-16 shrink-0 items-center">
        <img class="h-8 w-auto" src="/images/logo.png" alt="Your Company" />
      </div>
      <nav class="flex flex-1 flex-col">
        <ul role="list" class="flex flex-1 flex-col gap-y-7">
          <li>
            <ul role="list" class="-mx-2 space-y-1">
              <li>
                <a href={~p"/dashboard"} class={active("dashboard", @section)}>
                  <svg
                    class="h-6 w-6 shrink-0"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
                    />
                  </svg>
                  Dashboard
                </a>
              </li>
              <li>
                <a href={~p"/dashboard/uploads"} class={active("uploads", @section)}>
                  <.icon name="hero-arrow-up-on-square-stack" class="h-6 w-6 shrink-0" /> Upload Data
                </a>
              </li>

              <li>
                <a href={~p"/dashboard/tasks"} class={active("tasks", @section)}>
                  <.icon name="hero-clipboard-document-list" class="h-6 w-6 shrink-0" /> Tasks
                </a>
              </li>

              <li class="pt-10">
                <div class="text-xs font-semibold leading-6 text-gray-400">Management</div>
                <a href={~p"/dashboard/requests"} class={active("requests", @section)}>
                  <.icon name="hero-clipboard-document-check" class="h-6 w-6 shrink-0" />
                  Data Requests
                </a>
              </li>
              <li>
                <a href={~p"/dashboard/templates"} class={active("templates", @section)}>
                  <svg
                    class="h-6 w-6 shrink-0"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z"
                    />
                  </svg>
                  Metadata Collection Forms
                </a>
              </li>
              <li>
                <a href={~p"/dashboard/destinations"} class={active("destinations", @section)}>
                  <.icon name="hero-circle-stack" class="h-6 w-6 shrink-0" /> Destinations
                  Data Destinations
                </a>
              </li>
            </ul>
          </li>
          <li>
            <div class="text-xs font-semibold leading-6 text-gray-400">Your projects</div>
            <ul role="list" class="-mx-2 mt-2 space-y-1">
              <%= for {project, _count} <- projects_list(@current_user) do %>
                <li>
                  <a
                    href={~p"/dashboard/projects/#{project.id}"}
                    class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                  >
                    <span class="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-700 bg-gray-800 text-[0.625rem] font-medium text-gray-400 group-hover:text-white">
                      {String.at(project.name, 0)}
                    </span>
                    <span class="truncate">{project.name}</span>
                  </a>
                </li>
              <% end %>

              <li>
                <a
                  href="/dashboard/projects"
                  class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
                >
                  <.icon name="hero-plus" />
                  <span class="truncate">Find Projects</span>
                </a>
              </li>
            </ul>
          </li>
          <li class="mt-auto">
            <a href={~p"/users/settings"} class={active("settings", @section)}>
              <svg
                class="h-6 w-6 shrink-0"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                aria-hidden="true"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              Settings
            </a>
            <a
              href="mailto:Alexandria@inl.gov"
              class="text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
            >
              <.icon name="hero-bug-ant" class="bg-gray-400" /> Found a bug?
            </a>
          </li>
        </ul>
      </nav>
    </div>
    """
  end

  def active(section, selected) do
    if section == selected,
      do:
        "bg-gray-800 text-white group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold",
      else:
        "text-gray-400 hover:text-white hover:bg-gray-800 group flex gap-x-3 rounded-md p-2 text-sm leading-6 font-semibold"
  end

  def projects_list(current_user) do
    Ingest.Projects.list_own_projects_with_count(current_user.id)
  end

  def tasks_count(current_user) do
    Ingest.Uploads.count_uploads_missing_metadata(current_user)
  end
end
