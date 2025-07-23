defmodule AnvilWeb.Components.Common.FooterComponent do
  use AnvilWeb, :html

  @moduledoc """
  A simple footer component with copyright and technology stack information.
  """

  @doc """
  Renders a minimal footer with retro styling.

  ## Examples

      <.footer />
  """
  def footer(assigns) do
    ~H"""
    <footer class="footer footer-center p-4 border-t-2 border-primary text-base-content/60">
      <div class="text-xs font-mono">
        <p class="mb-1">
          © 2025
          <a
            href="https://github.com/anthropics/anvil"
            target="_blank"
            rel="noopener noreferrer"
            class="hover:text-primary transition-colors"
          >
            Anvil
          </a>
        </p>
        <p class="text-[10px]">
          Built with
          <a
            href="https://elixir-lang.org/"
            target="_blank"
            rel="noopener noreferrer"
            class="hover:text-primary transition-colors"
          >
            Elixir
          </a>
          |>
          <a
            href="https://www.phoenixframework.org/"
            target="_blank"
            rel="noopener noreferrer"
            class="hover:text-primary transition-colors"
          >
            Phoenix
          </a>
          |>
          <a
            href="https://ash-hq.org/"
            target="_blank"
            rel="noopener noreferrer"
            class="hover:text-primary transition-colors"
          >
            Ash
          </a>
        </p>
      </div>
    </footer>
    """
  end
end
