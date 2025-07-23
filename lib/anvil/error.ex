defmodule Anvil.Error do
  @moduledoc """
  Custom error for Anvil operations.
  """

  defexception [:reason]

  @impl true
  def message(%{reason: reason}) do
    case reason do
      :invalid_address_format ->
        "Invalid address format. Expected format: @repository/bundle@version/prompt_name"

      :project_not_found ->
        "Project not found"

      :prompt_set_not_found ->
        "Prompt set not found"

      :prompt_not_found ->
        "Prompt not found"

      {:template_error, details} ->
        "Template parsing error: #{inspect(details)}"

      {:render_error, details} ->
        "Template rendering error: #{details}"

      other ->
        "Anvil error: #{inspect(other)}"
    end
  end
end
