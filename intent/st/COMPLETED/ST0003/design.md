# Design - ST0003: Organisations Own Projects

## Overview

This design document outlines the transformation from user-owned projects to organisation-owned projects, implementing a multi-tenant architecture that supports both individual users and teams.

## Design Principles

1. **Backwards Compatible**: Individual users should not experience complexity
2. **Team-First**: Design for collaboration from the ground up  
3. **Security by Default**: Clear boundaries between organisations
4. **Role-Based**: Different permissions for different team members
5. **Future-Proof**: Support for advanced features like billing and limits

## Data Model Design

### Organisation Entity

```
Organisation
├── id (UUID)
├── name (String, unique)
├── slug (String, unique) 
├── description (String, optional)
├── personal? (Boolean, default: false)
├── created_at
└── updated_at
```

**Design Decisions**:
- `name` is globally unique to prevent confusion
- `slug` for URL-friendly identifiers
- `personal?` flag to distinguish auto-created personal orgs
- Personal organisations cannot be deleted

### Membership Entity

```
Membership (Join Table)
├── id (UUID)
├── user_id (FK to User)
├── organisation_id (FK to Organisation)
├── role (Enum: owner, admin, member)
├── created_at
└── updated_at
```

**Design Decisions**:
- Explicit join table for flexibility
- Three-tier role system:
  - **Owner**: Full control, can manage members
  - **Admin**: Can manage projects and content
  - **Member**: Can create and edit prompts
- Composite unique index on (user_id, organisation_id)

### Updated Project Relationship

```
Project
├── organisation_id (FK to Organisation) -- Changed from user_id
└── ... (other fields remain)
```

## Personal Organisation Pattern

Every user automatically receives a personal organisation on registration:
- Name: "[username]'s Personal"
- Slug: Generated with UUID suffix for uniqueness
- Personal flag: true
- Cannot be deleted
- User is automatically the owner

This ensures:
1. Consistent data model for all projects
2. Simple upgrade path for existing users
3. No UI complexity for individual users

## Authorization Design

### Ash Policy Structure

```elixir
# Organisation policies
policy action_type(:read) do
  authorize_if expr(exists(memberships, user_id == ^actor(:id)))
end

policy action(:update) do
  authorize_if expr(exists(memberships, user_id == ^actor(:id) and role == :owner))
end

# Project policies (updated)
policy always() do
  authorize_if expr(organisation.memberships.user_id == ^actor(:id))
end
```

### Role Permissions Matrix

| Action | Owner | Admin | Member |
|--------|-------|-------|---------|
| View organisation | ✓ | ✓ | ✓ |
| Edit organisation | ✓ | ✗ | ✗ |
| Delete organisation | ✓ | ✗ | ✗ |
| Manage members | ✓ | ✗ | ✗ |
| Create projects | ✓ | ✓ | ✗ |
| Edit projects | ✓ | ✓ | ✗ |
| Delete projects | ✓ | ✓ | ✗ |
| Create prompt sets | ✓ | ✓ | ✓ |
| Edit prompt sets | ✓ | ✓ | ✓ |
| Create prompts | ✓ | ✓ | ✓ |
| Edit prompts | ✓ | ✓ | ✓ |

## UI/UX Design

### Organisation Context

1. **Current Organisation**: Stored in session
2. **Organisation Switcher**: Dropdown in navigation
3. **Automatic Filtering**: All queries filtered by current org
4. **Personal Default**: Users start in their personal org

### Member Management

```
Organisation Settings
├── Members Tab
│   ├── List of current members with roles
│   ├── Invite by email
│   ├── Role management (for owners)
│   └── Remove member option
└── Settings Tab
    ├── Organisation name/description
    └── Danger zone (delete)
```

### Invitation Flow

1. **Existing Users**: Added immediately to organisation
2. **New Users**: 
   - Account created with temporary password
   - Magic link email sent
   - Added to organisation
   - Personal org created on first login

## Migration Strategy

1. **Create Organisations Table**: With all fields
2. **Create Memberships Table**: Join table
3. **Data Migration**:
   ```sql
   -- Create personal org for each user
   INSERT INTO organisations (name, slug, personal?, ...)
   SELECT 
     email || '''s Personal',
     generate_unique_slug(email),
     true,
     ...
   FROM users;
   
   -- Create owner memberships
   INSERT INTO memberships (user_id, organisation_id, role)
   SELECT u.id, o.id, 'owner'
   FROM users u
   JOIN organisations o ON o.name = u.email || '''s Personal';
   
   -- Migrate projects
   UPDATE projects 
   SET organisation_id = (
     SELECT o.id 
     FROM organisations o
     JOIN memberships m ON m.organisation_id = o.id
     WHERE m.user_id = projects.user_id
     AND o.personal? = true
   );
   ```

## Security Considerations

1. **Data Isolation**: Ash policies ensure complete isolation
2. **Role Validation**: Checked at policy level
3. **Invitation Security**: Only owners can invite
4. **Personal Org Protection**: Cannot be deleted or transferred
5. **Session Management**: Current org stored securely

## Future Extensibility

This design supports future features:
- **Billing**: Per-organisation subscriptions
- **Resource Limits**: Quotas per organisation
- **SSO**: Organisation-level authentication
- **Audit Logs**: Organisation activity tracking
- **API Keys**: Organisation-scoped keys
- **Peering**: Cross-organisation sharing (ST0004)