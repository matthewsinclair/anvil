# Implementation - ST0003: Organisations Own Projects

## Overview

The organisation-based multi-tenancy system has been fully implemented, transforming Anvil from a single-user system to a collaborative platform supporting teams while maintaining simplicity for individual users.

## Implementation Summary

### New Ash Resources

#### Organisation Resource
```elixir
defmodule Anvil.Organisations.Organisation do
  use Ash.Resource,
    domain: Anvil.Organisations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :slug, :string, allow_nil?: false, public?: true
    attribute :description, :string, public?: true
    attribute :personal?, :boolean, default: false, allow_nil?: false, public?: true
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_name, [:name]
    identity :unique_slug, [:slug]
  end

  policies do
    bypass action_type(:create) do
      authorize_if always()
    end

    bypass action_type(:read) do
      authorize_if expr(exists(memberships, user_id == ^actor(:id)))
    end

    policy action(:update) do
      authorize_if expr(exists(memberships, user_id == ^actor(:id) and role == :owner))
    end

    policy action(:destroy) do
      forbid_if expr(personal? == true)
      authorize_if expr(exists(memberships, user_id == ^actor(:id) and role == :owner))
    end
  end
end
```

#### Membership Resource
```elixir
defmodule Anvil.Organisations.Membership do
  use Ash.Resource,
    domain: Anvil.Organisations,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id
    attribute :role, :atom do
      constraints one_of: [:owner, :admin, :member]
      allow_nil? false
      default :member
      public? true
    end
  end

  relationships do
    belongs_to :organisation, Anvil.Organisations.Organisation do
      allow_nil? false
      attribute_writable? true
      primary_key? true
    end

    belongs_to :user, Anvil.Accounts.User do
      allow_nil? false
      attribute_writable? true
      primary_key? true
    end
  end

  identities do
    identity :unique_user_org, [:user_id, :organisation_id]
  end

  policies do
    policy action_type(:create) do
      authorize_if Anvil.Organisations.Checks.UserCanManageOrganisation
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(
        exists(organisation.memberships, user_id == ^actor(:id) and role == :owner)
      )
    end
  end
end
```

### Key Implementation Details

#### Automatic Personal Organisation Creation
```elixir
defmodule Anvil.Accounts.Changes.CreatePersonalOrganisation do
  use Ash.Resource.Change

  def change(changeset, _, _) do
    changeset
    |> Ash.Changeset.after_action(fn changeset, user ->
      if changeset.action_type == :create do
        with {:ok, organisation} <- create_personal_organisation(user),
             {:ok, _membership} <- create_owner_membership(user, organisation) do
          {:ok, user}
        end
      else
        {:ok, user}
      end
    end)
  end

  defp create_personal_organisation(user) do
    username = user.email |> to_string() |> String.split("@") |> List.first()
    
    Anvil.Organisations.create_organisation(
      %{
        name: "#{username}'s Personal",
        description: "Personal organisation for #{user.email}",
        personal?: true
      },
      authorize?: false
    )
  end
end
```

#### Slug Generation with Uniqueness
```elixir
defmodule Anvil.Organisations.Changes.GenerateSlug do
  use Ash.Resource.Change

  def change(changeset, _, _) do
    case Ash.Changeset.get_attribute(changeset, :name) do
      nil -> changeset
      name ->
        is_personal = Ash.Changeset.get_attribute(changeset, :personal?)
        
        slug = if is_personal do
          # Personal orgs get UUID suffix for uniqueness
          base_slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9\s-]/, "") |> String.replace(~r/\s+/, "-")
          uuid_suffix = Ash.UUID.generate() |> String.slice(0..7)
          "#{base_slug}-#{uuid_suffix}"
        else
          # Regular orgs use name-based slug
          name |> String.downcase() |> String.replace(~r/[^a-z0-9\s-]/, "") |> String.replace(~r/\s+/, "-")
        end

        Ash.Changeset.force_change_attribute(changeset, :slug, slug)
    end
  end
end
```

#### Custom Policy Check for Membership Creation
```elixir
defmodule Anvil.Organisations.Checks.UserCanManageOrganisation do
  use Ash.Policy.SimpleCheck

  def match?(actor, %{changeset: changeset}, _opts) do
    org_id = Ash.Changeset.get_argument(changeset, :organisation_id) ||
             Ash.Changeset.get_attribute(changeset, :organisation_id)

    case org_id do
      nil -> false
      organisation_id ->
        # Allow first membership (creating org) or if user is owner
        existing_count = 
          Anvil.Organisations.Membership
          |> filter(organisation_id == ^organisation_id)
          |> Ash.count!(actor: actor, authorize?: false)
        
        if existing_count == 0 do
          true
        else
          owner_count =
            Anvil.Organisations.Membership
            |> filter(organisation_id == ^organisation_id and user_id == ^actor.id and role == :owner)
            |> Ash.count!(actor: actor, authorize?: false)
            
          owner_count > 0
        end
    end
  end
end
```

### LiveView Integration

**Note**: The organisation switcher currently triggers a page reload rather than updating the session directly. This is a temporary implementation that ensures context is properly updated across all LiveViews.

#### Organisation Context Management
```elixir
defmodule AnvilWeb.LiveUserAuth do
  def on_mount(:live_user_required, _params, session, socket) do
    socket = AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)

    if socket.assigns[:current_user] do
      ensure_personal_organisation(socket.assigns.current_user)
      socket = assign_current_organisation(socket, session)
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  defp assign_current_organisation(socket, session) do
    user = socket.assigns.current_user
    current_org_id = session["current_organisation_id"]
    
    user_with_orgs = Ash.load!(user, [memberships: :organisation], authorize?: false)
    organisations = Enum.map(user_with_orgs.memberships, & &1.organisation)

    current_organisation =
      if current_org_id do
        Enum.find(organisations, fn org -> org.id == current_org_id end)
      end || List.first(organisations)

    socket
    |> assign(:organisations, organisations)
    |> assign(:current_organisation, current_organisation)
    |> assign(:user_memberships, user_with_orgs.memberships)
  end
  
  defp ensure_personal_organisation(user) do
    # Auto-create personal org if missing (for invited users)
    user_with_memberships = Ash.load!(user, [memberships: :organisation], authorize?: false)
    
    has_personal_org = 
      user_with_memberships.memberships
      |> Enum.any?(fn membership -> membership.organisation.personal? end)
    
    unless has_personal_org do
      # Create personal organisation for the user
      # ... (implementation shown above)
    end
  end
end
```

#### Organisation Switcher Component
```elixir
defmodule AnvilWeb.CoreComponents do
  def organisation_switcher(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <label tabindex="0" class="btn btn-ghost btn-sm normal-case">
        <span class="text-primary">{@current_organisation.name}</span>
        <svg class="fill-current h-4 w-4 ml-1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
          <path d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" />
        </svg>
      </label>
      <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 border-2 border-primary">
        <li :for={org <- @organisations}>
          <a 
            href={~p"/switch_organisation/#{org.id}"}
            class={[
              "font-mono",
              @current_organisation.id == org.id && "active"
            ]}
          >
            {org.name}
            <span :if={org.personal?} class="badge badge-xs badge-secondary">Personal</span>
          </a>
        </li>
        <li class="menu-title">
          <span>Actions</span>
        </li>
        <li>
          <.link href={~p"/organisations"} class="font-mono">
            Manage Organisations
          </.link>
        </li>
      </ul>
    </div>
    """
  end
end
```

### User Invitation System

#### Custom Action for Invitations
```elixir
defmodule Anvil.Accounts.Actions.InviteToOrganisation do
  def run(input, _opts, context) do
    email = input.arguments.email
    organisation_id = input.arguments.organisation_id
    role = input.arguments.role
    actor = context.actor
    
    # Check if user exists
    query = Ash.Query.for_read(Anvil.Accounts.User, :get_by_email, %{email: email})
    
    case Ash.read_one(query, actor: actor, authorize?: false) do
      {:ok, user} when not is_nil(user) ->
        # User exists, add to organisation
        create_membership(user, organisation_id, role, actor)
        
      {:ok, nil} ->
        # User doesn't exist, create and invite
        create_user_and_invite(email, organisation_id, role, actor)
    end
  end
  
  defp create_user_and_invite(email, organisation_id, role, actor) do
    # Create user with temporary password
    temp_password = :crypto.strong_rand_bytes(20) |> Base.encode64()
    
    case Anvil.Accounts.User
         |> Ash.Changeset.for_create(:register_with_password, %{
           email: email,
           password: temp_password,
           password_confirmation: temp_password
         })
         |> Ash.create(authorize?: false) do
      {:ok, user} ->
        # Add to organisation
        case Organisations.create_membership(%{
          user_id: user.id,
          organisation_id: organisation_id,
          role: role
        }, actor: actor) do
          {:ok, _membership} ->
            # Send magic link
            action_input = 
              Anvil.Accounts.User
              |> Ash.ActionInput.for_action(:request_magic_link, %{email: email})
              
            case Ash.run_action(action_input, authorize?: false) do
              :ok -> :ok
              {:error, error} ->
                # Cleanup on failure
                Ash.destroy(user, authorize?: false)
                {:error, error}
            end
        end
    end
  end
end
```

### Migration Implementation

**Note**: The migration file has a typo in the filename (`add_orgainisations.exs` instead of `add_organisations.exs`). This is cosmetic only and doesn't affect functionality.

```elixir
defmodule Anvil.Repo.Migrations.AddOrganisations do
  use Ecto.Migration

  def change do
    # Create organisations table
    create table(:organisations, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :personal?, :boolean, default: false, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:organisations, [:name])
    create unique_index(:organisations, [:slug])

    # Create memberships table
    create table(:organisation_memberships, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :organisation_id, references(:organisations, type: :uuid, on_delete: :delete_all), null: false
      add :role, :string, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:organisation_memberships, [:user_id, :organisation_id])
    create index(:organisation_memberships, [:organisation_id])
    create index(:organisation_memberships, [:user_id])

    # Update projects table
    alter table(:projects) do
      add :organisation_id, references(:organisations, type: :uuid, on_delete: :delete_all)
    end

    create index(:projects, [:organisation_id])
  end
end
```

## UI Implementation

### Organisation Management Pages

#### Organisation List (`OrganisationLive.Index`)
- Shows all organisations user is member of
- Member count for each organisation
- Create new organisation form
- Personal organisations marked with badge

#### Organisation Details (`OrganisationLive.Show`)
- Member list with roles
- Invite member functionality (email-based)
- Role management for owners
- Remove member capability
- Danger zone for organisation deletion (non-personal only)

### Integration Points

1. **Project Creation**: Hidden organisation_id field set to current org
2. **Navigation**: Organisation switcher in top nav
3. **Breadcrumbs**: Organisation context shown in trail
4. **Data Filtering**: All queries automatically filtered by current org

## Challenges Solved

### Personal Organisation Uniqueness
**Problem**: All personal orgs named "Personal" violates unique constraint
**Solution**: Generate unique names like "matthew.sinclair's Personal" with UUID-suffixed slugs

### Invited User Flow
**Problem**: Users created via invitation didn't get personal organisations
**Solution**: Added `ensure_personal_organisation` check on login

### Role Change UI
**Problem**: Phoenix's `phx-change` event handling for dropdowns
**Solution**: Wrapped select in form tag to properly capture events

### Policy Complexity
**Problem**: Create actions need special handling for first membership
**Solution**: Custom policy check that allows first membership creation

## Performance Considerations

1. **N+1 Query Prevention**: Load memberships and organisations together
2. **Session Storage**: Only store organisation ID, not full object
3. **Policy Caching**: Ash automatically caches policy checks within request
4. **Index Usage**: Added database indexes on foreign keys

## Security Implementation

1. **Complete Data Isolation**: Policies ensure no cross-org data access
2. **Role Enforcement**: All actions check role at policy level
3. **Personal Org Protection**: Cannot be deleted via policy
4. **Invitation Security**: Only owners can invite new members
5. **Session Security**: Organisation context stored in encrypted session

## Testing Considerations

Areas requiring comprehensive testing:
1. Policy enforcement across all resources
2. Organisation switching functionality
3. Invitation flow for new/existing users
4. Personal organisation auto-creation
5. Role-based permissions matrix
6. Data migration for existing users