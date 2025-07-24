defmodule Anvil.AshHelpers do
  @moduledoc """
  Helper functions for working with Ash errors in tests.
  """

  @doc """
  Extracts error messages from Ash errors into a map format similar to Ecto's errors_on.

  ## Examples

      assert %{email: ["has already been taken"]} = ash_errors_on(error)
      assert "is required" in ash_errors_on(error).password
  """
  def ash_errors_on(%Ash.Error.Invalid{errors: errors}) do
    Enum.reduce(errors, %{}, fn error, acc ->
      field = extract_field(error)
      message = extract_message(error)

      if field && message do
        Map.update(acc, field, [message], fn messages -> messages ++ [message] end)
      else
        acc
      end
    end)
  end

  def ash_errors_on(%Ash.Error.Forbidden{errors: _errors}) do
    # For forbidden errors, we might want to handle differently
    # For now, return a generic forbidden message
    %{base: ["forbidden"]}
  end

  def ash_errors_on(_other) do
    # Fallback for other error types
    %{}
  end

  defp extract_field(%{field: field}) when is_atom(field), do: field
  defp extract_field(_), do: nil

  defp extract_message(%{message: message}) when is_binary(message), do: message

  defp extract_message(%{message: message, vars: vars}) when is_binary(message) do
    # Simple variable interpolation
    Enum.reduce(vars, message, fn {key, value}, msg ->
      String.replace(msg, "%{#{key}}", to_string(value))
    end)
  end

  defp extract_message(_), do: nil
end
