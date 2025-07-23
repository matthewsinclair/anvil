defmodule Anvil.Types.ParameterList do
  @moduledoc """
  A custom type for handling arrays of parameter maps that are stored as jsonb[] in PostgreSQL.
  """
  use Ash.Type

  @impl true
  def storage_type(_), do: {:array, :map}

  @impl true
  def cast_input(nil, _), do: {:ok, []}

  def cast_input(value, _) when is_list(value) do
    casted =
      value
      |> Enum.reject(&empty_parameter?/1)
      |> Enum.map(&cast_parameter/1)

    {:ok, casted}
  end

  def cast_input(_, _), do: {:ok, []}

  @impl true
  def cast_stored(nil, _), do: {:ok, []}
  def cast_stored(value, _) when is_list(value), do: {:ok, value}
  def cast_stored(_, _), do: {:ok, []}

  @impl true
  def dump_to_native(nil, _), do: {:ok, []}

  def dump_to_native(value, _) when is_list(value) do
    dumped = Enum.map(value, &ensure_map/1)
    {:ok, dumped}
  end

  def dump_to_native(_, _), do: {:ok, []}

  defp empty_parameter?(param) when is_map(param) do
    Map.get(param, "name", "") == ""
  end

  defp empty_parameter?(_), do: true

  defp cast_parameter(param) when is_map(param) do
    %{
      "name" => to_string(Map.get(param, "name", "")),
      "type" => to_string(Map.get(param, "type", "string")),
      "required" => to_boolean(Map.get(param, "required", false))
    }
  end

  defp cast_parameter(_), do: %{"name" => "", "type" => "string", "required" => false}

  defp ensure_map(param) when is_map(param), do: param
  defp ensure_map(_), do: %{}

  defp to_boolean(true), do: true
  defp to_boolean("true"), do: true
  defp to_boolean(_), do: false
end
