defmodule Anvil.Template.Analyzer do
  @moduledoc """
  Analyzes Liquid templates to extract variables and validate parameters.
  """

  @variable_regex ~r/\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}\}/

  @doc """
  Extracts all variable names from a Liquid template.

  Returns a list of unique variable names found in the template.
  """
  @spec extract_variables(String.t()) :: [String.t()]
  def extract_variables(template) when is_binary(template) do
    @variable_regex
    |> Regex.scan(template, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  def extract_variables(_), do: []

  @doc """
  Validates template variables against defined parameters.

  Returns a map with:
  - :missing - variables in template but not in parameters
  - :unused - parameters defined but not used in template
  - :matched - parameters that are used in the template
  """
  @spec validate_parameters(String.t(), [map()]) :: %{
          missing: [String.t()],
          unused: [String.t()],
          matched: [String.t()]
        }
  def validate_parameters(template, parameters)
      when is_binary(template) and is_list(parameters) do
    template_vars = extract_variables(template)

    param_names =
      parameters
      |> Enum.map(fn param ->
        Map.get(param, "name") || Map.get(param, :name) || ""
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    missing = template_vars -- param_names
    unused = param_names -- template_vars
    matched = template_vars -- missing

    %{
      missing: missing,
      unused: unused,
      matched: matched
    }
  end

  def validate_parameters(_, _), do: %{missing: [], unused: [], matched: []}

  @doc """
  Creates parameter definitions for missing variables.

  Returns a list of parameter maps with default settings.
  """
  @spec create_parameter_definitions([String.t()]) :: [map()]
  def create_parameter_definitions(variable_names) when is_list(variable_names) do
    Enum.map(variable_names, fn name ->
      %{
        "name" => name,
        "type" => "string",
        "required" => false
      }
    end)
  end

  def create_parameter_definitions(_), do: []

  @doc """
  Checks if a template is valid (has all required parameters defined).
  """
  @spec valid?(String.t(), [map()]) :: boolean()
  def valid?(template, parameters) do
    validation = validate_parameters(template, parameters)
    Enum.empty?(validation.missing)
  end
end
