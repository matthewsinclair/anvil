defmodule Anvil.Template do
  @moduledoc """
  Template rendering using Liquid syntax via the Solid library.
  """

  @spec render(String.t(), keyword() | map()) :: {:ok, String.t()} | {:error, term()}
  def render(template, params) do
    context = build_context(params)

    case Solid.parse(template) do
      {:ok, parsed} ->
        try do
          rendered =
            Solid.render!(parsed, context,
              strict_variables: true,
              custom_filters: [Anvil.Template.Filters]
            )

          {:ok, rendered}
        rescue
          e -> {:error, {:render_error, Exception.message(e)}}
        end

      {:error, error} ->
        {:error, {:template_error, error}}
    end
  end

  defp build_context(params) when is_list(params) do
    params
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Map.new()
  end

  defp build_context(params) when is_map(params) do
    params
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Map.new()
  end
end
