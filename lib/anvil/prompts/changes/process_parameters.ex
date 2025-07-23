defmodule Anvil.Prompts.Changes.ProcessParameters do
  use Ash.Resource.Change

  @moduledoc """
  Processes parameters from form submission to ensure they are properly
  formatted as maps for storage in PostgreSQL jsonb[] column.
  """

  @impl true
  def change(changeset, _, _) do
    case Ash.Changeset.get_attribute(changeset, :parameters) do
      nil ->
        Ash.Changeset.change_attribute(changeset, :parameters, [])

      params when is_list(params) ->
        processed_params =
          params
          |> Enum.reject(&empty_parameter?/1)
          |> Enum.map(&ensure_map/1)

        Ash.Changeset.change_attribute(changeset, :parameters, processed_params)

      _ ->
        Ash.Changeset.change_attribute(changeset, :parameters, [])
    end
  end

  @impl true
  def atomic(_changeset, _opts, _context) do
    # Parameters need to be processed in the change callback
    # before being sent to the database, so we can't make this atomic
    :not_atomic
  end

  defp empty_parameter?(param) when is_map(param) do
    Map.get(param, "name", "") == ""
  end

  defp empty_parameter?(_), do: true

  defp ensure_map(param) when is_map(param) do
    %{
      "name" => to_string(Map.get(param, "name", "")),
      "type" => to_string(Map.get(param, "type", "string")),
      "required" => to_boolean(Map.get(param, "required", false))
    }
  end

  defp ensure_map(_), do: %{"name" => "", "type" => "string", "required" => false}

  defp to_boolean(true), do: true
  defp to_boolean("true"), do: true
  defp to_boolean(_), do: false
end
