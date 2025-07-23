defmodule Anvil.Prompts.Changes.GenerateSlug do
  use Ash.Resource.Change
  require Ash.Expr

  @moduledoc """
  Generates a slug from the name attribute for prompts.
  """

  @impl true
  def change(changeset, _, _) do
    case Ash.Changeset.get_attribute(changeset, :name) do
      nil ->
        changeset

      name ->
        slug = name |> String.downcase() |> String.replace(" ", "-")
        Ash.Changeset.change_attribute(changeset, :slug, slug)
    end
  end

  @impl true
  def atomic(_changeset, _opts, _context) do
    # Use Ash expression to generate slug atomically
    {:ok, %{slug: Ash.Expr.expr(fragment("lower(replace(?, ' ', '-'))", ^ref(:name)))}}
  end
end
