defmodule Anvil.Template.Filters do
  @moduledoc """
  Custom Liquid filters for Anvil templates.
  """

  def for_model(input, args, _context) do
    model = List.first(args) || "gpt-4"

    case model do
      "gpt-4" -> "GPT-4: #{input}"
      "claude" -> "Claude: #{input}"
      _ -> input
    end
  end

  def count_tokens(input, _args, _context) do
    # Simple token approximation - actual implementation would use proper tokenizer
    words = String.split(to_string(input), ~r/\s+/)
    (length(words) * 1.3) |> round()
  end

  def compose_with(input, args, _context) do
    other_prompt = List.first(args)

    if other_prompt do
      "#{input}\n\n---\n\n#{other_prompt}"
    else
      input
    end
  end
end
