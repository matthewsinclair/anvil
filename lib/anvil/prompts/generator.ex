defmodule Anvil.Prompts.Generator do
  @moduledoc """
  Generator module for creating test data for the Prompts domain.

  This module uses Ash.Generator to create test prompt sets, prompts, and versions
  while respecting Ash validations and policies.
  """
  use Ash.Generator

  # Import only specific functions to avoid conflicts
  import Anvil.Projects.Generator, only: [project: 0, project_with_full_context: 1]

  @doc """
  Generate a test prompt set.

  ## Options
  - `:name` - Override the default name sequence
  - `:version` - Version string (default: "1.0.0")
  - `:project_id` - The project this belongs to (required if not provided)
  - `:published_at` - When the prompt set was published

  ## Examples

      iex> prompt_set = generate(prompt_set(project_id: project.id))
      iex> published_set = generate(prompt_set(project_id: project.id, published_at: DateTime.utc_now()))
  """
  def prompt_set(opts \\ []) do
    project_id =
      opts[:project_id] ||
        once(:default_project_id, fn ->
          generate(project()).id
        end)

    # Use a counter for unique prompt set names
    set_num = System.unique_integer([:positive])
    name = opts[:name] || "Prompt Set #{set_num}"

    # Create through the action to trigger slug generation
    Anvil.Prompts.PromptSet
    |> Ash.Changeset.for_create(:create, %{
      name: name,
      version: opts[:version] || "1.0.0",
      project_id: project_id
    })
    |> Ash.create!(authorize?: false)
  end

  @doc """
  Generate a test prompt with valid Liquid template.

  ## Options
  - `:name` - Override the default name sequence
  - `:template` - Liquid template string
  - `:parameters` - List of parameter maps
  - `:prompt_set_id` - The prompt set this belongs to (required if not provided)

  ## Examples

      iex> prompt = generate(prompt(prompt_set_id: set.id))
      iex> custom_prompt = generate(prompt(
      ...>   prompt_set_id: set.id,
      ...>   template: "Hello {{ user_name }}, welcome to {{ app_name }}!"
      ...> ))
  """
  def prompt(opts \\ []) do
    prompt_set_id =
      opts[:prompt_set_id] ||
        once(:default_prompt_set_id, fn ->
          generate(prompt_set()).id
        end)

    # Default template with common Liquid syntax patterns
    default_template = ~S"""
    Hello {{ name }}!

    {% if show_welcome %}
    Welcome to our service.
    {% endif %}

    {% for item in items %}
    - {{ item }}
    {% endfor %}

    Best regards,
    {{ sender_name | default: "The Team" }}
    """

    # Use a counter for unique prompt names
    prompt_num = System.unique_integer([:positive])
    name = opts[:name] || "Prompt #{prompt_num}"
    template = opts[:template] || default_template

    # Extract parameters from template if not provided
    parameters = opts[:parameters] || extract_parameters(template)

    # Create through the action to trigger slug generation
    Anvil.Prompts.Prompt
    |> Ash.Changeset.for_create(:create, %{
      name: name,
      template: template,
      parameters: parameters,
      metadata: opts[:metadata] || %{},
      prompt_set_id: prompt_set_id
    })
    |> Ash.create!(authorize?: false)
  end

  @doc """
  Generate a complete prompt hierarchy with project context.

  Returns a map with :user, :organisation, :project, :prompt_set, and :prompts keys.

  ## Options
  - `:prompt_count` - Number of prompts to create (default: 3)

  ## Examples

      iex> result = prompt_hierarchy()
      iex> result.prompts |> length()
      3
  """
  def prompt_hierarchy(opts \\ []) do
    # Get full project context
    context = project_with_full_context(opts)

    # Create prompt set
    prompt_set = generate(prompt_set(project_id: context.project.id))

    # Create prompts
    prompt_count = Keyword.get(opts, :prompt_count, 3)

    prompts =
      Enum.map(1..prompt_count, fn i ->
        generate(
          prompt(
            name: "Prompt #{i}",
            prompt_set_id: prompt_set.id,
            template: sample_template(i)
          )
        )
      end)

    Map.merge(context, %{
      prompt_set: prompt_set,
      prompts: prompts
    })
  end

  # Private helpers

  defp extract_parameters(template) do
    # Simple parameter extraction from Liquid template
    # In production, this is done by Anvil.Template.Analyzer
    regex = ~r/\{\{\s*(\w+)(?:\s*\|[^}]+)?\s*\}\}/

    regex
    |> Regex.scan(template)
    |> Enum.map(fn [_, param] -> param end)
    |> Enum.uniq()
    |> Enum.map(fn param ->
      %{
        "name" => param,
        "type" => "string",
        "required" => true,
        "description" => "Parameter #{param}"
      }
    end)
  end

  defp sample_template(1) do
    ~S"""
    Dear {{ customer_name }},

    Your order #{{ order_number }} has been {{ status }}.

    {% if tracking_number %}
    Tracking number: {{ tracking_number }}
    {% endif %}

    Thank you for your business!
    """
  end

  defp sample_template(2) do
    ~S"""
    Subject: {{ subject }}

    Hi {{ recipient_name | default: "there" }},

    {{ message_body }}

    {% for attachment in attachments %}
    - Attached: {{ attachment.name }}
    {% endfor %}

    Best regards,
    {{ sender_name }}
    """
  end

  defp sample_template(_) do
    ~S"""
    {{ greeting | default: "Hello" }} {{ name }}!

    {% case notification_type %}
    {% when "alert" %}
      ⚠️ This is an alert: {{ alert_message }}
    {% when "info" %}
      ℹ️ For your information: {{ info_message }}
    {% else %}
      📢 {{ general_message }}
    {% endcase %}

    Sent on {{ date | date: "%B %d, %Y" }}
    """
  end
end
