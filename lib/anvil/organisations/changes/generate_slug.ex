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
        # Check if this is a personal organisation
        is_personal = Ash.Changeset.get_attribute(changeset, :personal?)

        slug =
          if is_personal do
            # For personal orgs, generate a unique slug with UUID suffix
            base_slug =
              name
              |> String.downcase()
              |> String.replace(~r/[^a-z0-9\s-]/, "")
              |> String.replace(~r/\s+/, "-")

            uuid_suffix = Ash.UUID.generate() |> String.slice(0..7)
            "#{base_slug}-#{uuid_suffix}"
          else
            # For regular orgs, use the name as-is
            name
            |> String.downcase()
            |> String.replace(~r/[^a-z0-9\s-]/, "")
            |> String.replace(~r/\s+/, "-")
          end

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
