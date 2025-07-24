---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 4. Data Model

## Domain Model Overview

Anvil's data model is organised around four primary domains, each representing a bounded context in the system:

```
┌─────────────────┐
│  Organisations  │
│                 │
│ ┌─────────────┐ │     ┌─────────────┐
│ │Organisation │ ├─────┤ Membership  ├──────┐
│ └─────┬───────┘ │     └─────────────┘      │
└────────│────────┘                          │
         │                                   │
         │ owns                              │
         ▼                                   ▼
┌─────────────────┐                  ┌─────────────┐
│    Projects     │                  │  Accounts   │
│                 │                  │             │
│ ┌────────────┐  │                  │ ┌────────┐  │
│ │  Project   │  │                  │ │  User  │  │
│ └─────┬──────┘  │                  │ └────────┘  │
└────────│────────┘                  └─────────────┘
         │
         │ contains
         ▼
┌─────────────────┐
│     Prompts     │
│                 │
│ ┌─────────────┐ │
│ │ PromptSet   ├─────┐
│ └─────┬───────┘ │   │
│       │         │   │
│ ┌─────▼─────┐   │   │
│ │  Prompt   │   │   │
│ └───────────┘   │   │
│                 │   │
│ ┌───────────┐   │   │
│ │  Version  ├───────┘
│ └───────────┘   │
└─────────────────┘
```

## Entity Specifications

### Organisations Domain

#### Organisation

```sql
CREATE TABLE organisations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    personal BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX idx_organisations_name ON organisations(name);
CREATE UNIQUE INDEX idx_organisations_slug ON organisations(slug);
```

**Key Attributes:**

- `name`: Display name, globally unique
- `slug`: URL-friendly identifier
- `personal`: Flag for auto-created personal orgs
- `description`: Optional organisation description

#### Membership

```sql
CREATE TABLE organisation_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organisation_id UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX idx_memberships_user_org ON organisation_memberships(user_id, organisation_id);
CREATE INDEX idx_memberships_org ON organisation_memberships(organisation_id);
CREATE INDEX idx_memberships_user ON organisation_memberships(user_id);
```

**Key Attributes:**

- `role`: Enum of owner, admin, member
- Composite unique constraint on user/org pair

### Accounts Domain

#### User

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(160) NOT NULL UNIQUE,
    hashed_password VARCHAR(255),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX idx_users_email ON users(email);
```

**Key Attributes:**

- `email`: Primary identifier, unique
- `hashed_password`: Bcrypt hashed, nullable for magic link users
- `confirmed_at`: Email verification timestamp

#### Token

```sql
CREATE TABLE users_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token BYTEA NOT NULL,
    context VARCHAR(255) NOT NULL,
    sent_to VARCHAR(255),
    inserted_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_users_tokens_user ON users_tokens(user_id);
CREATE INDEX idx_users_tokens_context_token ON users_tokens(context, token);
```

### Projects Domain

#### Project

```sql
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id UUID NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX idx_projects_org_name ON projects(organisation_id, name);
CREATE UNIQUE INDEX idx_projects_org_slug ON projects(organisation_id, slug);
CREATE INDEX idx_projects_org ON projects(organisation_id);
```

**Key Attributes:**

- `name`: Project display name
- `slug`: URL-friendly identifier
- Unique within organisation scope

### Prompts Domain

#### PromptSet

```sql
CREATE TABLE prompt_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX idx_prompt_sets_project_name ON prompt_sets(project_id, name);
CREATE UNIQUE INDEX idx_prompt_sets_project_slug ON prompt_sets(project_id, slug);
CREATE INDEX idx_prompt_sets_project ON prompt_sets(project_id);
```

#### Prompt

```sql
CREATE TABLE prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_set_id UUID NOT NULL REFERENCES prompt_sets(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT,
    template TEXT NOT NULL,
    parameters JSONB[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX idx_prompts_set_name ON prompts(prompt_set_id, name);
CREATE UNIQUE INDEX idx_prompts_set_slug ON prompts(prompt_set_id, slug);
CREATE INDEX idx_prompts_set ON prompts(prompt_set_id);
```

**Key Attributes:**

- `template`: Liquid template syntax
- `parameters`: JSONB array of parameter definitions

**Parameter Schema:**

```json
{
  "name": "string",
  "type": "string|number|boolean",
  "description": "string",
  "required": "boolean",
  "default": "any"
}
```

#### Version

```sql
CREATE TABLE versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_set_id UUID NOT NULL REFERENCES prompt_sets(id) ON DELETE CASCADE,
    label VARCHAR(255) NOT NULL,
    snapshot JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_versions_prompt_set ON versions(prompt_set_id);
CREATE INDEX idx_versions_created ON versions(created_at DESC);
```

**Key Attributes:**

- `label`: Human-readable version identifier
- `snapshot`: Complete state at version time
- Immutable after creation

## Relationships

### Primary Relationships

1. **Organisation → Projects** (1:N)
   - Organisation owns many projects
   - Project belongs to one organisation
   - Cascade delete

2. **Organisation → Memberships** (1:N)
   - Organisation has many members
   - Membership links user to org with role

3. **User → Memberships** (1:N)
   - User can belong to multiple orgs
   - Each membership has a role

4. **Project → PromptSets** (1:N)
   - Project contains many prompt sets
   - Prompt set belongs to one project

5. **PromptSet → Prompts** (1:N)
   - Prompt set contains many prompts
   - Prompt belongs to one set

6. **PromptSet → Versions** (1:N)
   - Prompt set has version history
   - Version captures point-in-time state

## Data Integrity

### Constraints

1. **Unique Constraints**
   - Organisation name/slug globally unique
   - Project name/slug unique within org
   - Prompt set name/slug unique within project
   - Prompt name/slug unique within set
   - User email globally unique
   - User/org membership pair unique

2. **Foreign Key Constraints**
   - All use CASCADE DELETE
   - Ensures referential integrity
   - Prevents orphaned records

3. **Check Constraints**
   - Role must be valid enum value
   - Personal flag is boolean
   - Timestamps are required

### Business Rules

1. **Personal Organisations**
   - Cannot be deleted
   - One per user
   - Auto-created on registration
   - Name pattern: "[username]'s Personal"

2. **Role Hierarchy**
   - Owner > Admin > Member
   - At least one owner per org
   - Owners can manage all aspects
   - Admins can manage projects/prompts
   - Members can create/edit prompts

3. **Slug Generation**
   - Auto-generated from name
   - URL-safe characters only
   - Personal orgs get UUID suffix
   - Must be unique at each level

## Performance Considerations

### Indexes

1. **Primary Keys**: UUID with B-tree index
2. **Foreign Keys**: Indexed for join performance
3. **Unique Constraints**: Enforce business rules
4. **Composite Indexes**: For common query patterns
5. **Partial Indexes**: Could be added for filtered queries

### Query Patterns

1. **Organisation Context**

   ```sql
   SELECT * FROM projects WHERE organisation_id = ?
   ```

2. **User Memberships**

   ```sql
   SELECT o.*, m.role 
   FROM organisations o
   JOIN organisation_memberships m ON o.id = m.organisation_id
   WHERE m.user_id = ?
   ```

3. **Prompt Hierarchy**

   ```sql
   SELECT ps.*, p.*
   FROM prompt_sets ps
   JOIN prompts p ON ps.id = p.prompt_set_id
   WHERE ps.project_id = ?
   ```

## Migration Strategy

### Initial Schema

1. Create all tables in order of dependencies
2. Add indexes after data load
3. Validate constraints

### Future Migrations

1. Add columns as nullable first
2. Backfill data
3. Add constraints after backfill
4. Use database transactions

## Data Volume Projections

### Expected Scale

- Organisations: 10,000s
- Users: 100,000s
- Projects: 100,000s
- Prompts: 1,000,000s
- Versions: 10,000,000s

### Growth Patterns

- Linear growth for orgs/users
- Exponential growth for prompts/versions
- Seasonal spikes expected
- Archive strategy needed for old versions
