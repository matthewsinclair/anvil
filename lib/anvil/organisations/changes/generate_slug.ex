defmodule Anvil.Organisations.Changes.GenerateSlug do
  use Ash.Resource.Change
  require Ash.Expr

  @moduledoc """
  Generates a slug from the name attribute for organisations.
  """

  @impl true
  def change(changeset, _, _) do
    case Ash.Changeset.get_attribute(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")

        Ash.Changeset.force_change_attribute(changeset, :slug, slug)
    end
  end

  @impl true
  def atomic(_changeset, _opts, _context) do
    {:ok,
     %{
       slug:
         Ash.Expr.expr(
           fragment(
             "lower(regexp_replace(regexp_replace(?, '[^a-zA-Z0-9\\s-]', '', 'g'), '\\s+', '-', 'g'))",
             ^ref(:name)
           )
         )
     }}
  end
end
