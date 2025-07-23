defmodule AnvilWeb.Components.Common.BreadcrumbComponent do
  use AnvilWeb, :html

  @moduledoc """
  Breadcrumb navigation component with 8-bit retro theme.
  """

  @doc """
  Renders breadcrumb navigation.

  ## Examples

      <.breadcrumb items={[
        %{label: "Projects", href: ~p"/projects"},
        %{label: "My Project", href: ~p"/projects/123"},
        %{label: "Prompt Sets", current: true}
      ]} />
  """
  attr :items, :list, required: true

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="text-sm font-mono mb-6">
      <ol class="flex items-center gap-2">
        <%= for {item, index} <- Enum.with_index(@items) do %>
          <%= if index > 0 do %>
            <li class="flex items-center gap-2">
              <span class="text-base-content/60">›</span>
              <%= if Map.get(item, :current, false) do %>
                <span class="text-primary uppercase">
                  {item.label}
                </span>
              <% else %>
                <.link
                  navigate={item.href}
                  class="text-primary underline hover:no-underline uppercase"
                >
                  {item.label}
                </.link>
              <% end %>
            </li>
          <% else %>
            <li>
              <%= if Map.get(item, :current, false) do %>
                <span class="text-primary uppercase">
                  {item.label}
                </span>
              <% else %>
                <.link
                  navigate={item.href}
                  class="text-primary underline hover:no-underline uppercase"
                >
                  {item.label}
                </.link>
              <% end %>
            </li>
          <% end %>
        <% end %>
      </ol>
    </nav>
    """
  end
end
