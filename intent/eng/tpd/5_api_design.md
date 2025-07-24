---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 5. API Design

## Overview

Anvil provides a RESTful API for programmatic access to prompt management functionality. The API follows REST principles with JSON payloads and uses standard HTTP methods and status codes.

## API Principles

1. **RESTful Design**: Resources are nouns, HTTP methods are verbs
2. **Consistent Structure**: Predictable URL patterns and response formats
3. **Versioning**: URL-based versioning (`/api/v1/`)
4. **Authentication**: API key in Authorization header
5. **JSON Format**: All requests and responses use JSON
6. **Pagination**: Cursor-based for large result sets
7. **Error Handling**: Consistent error response structure

## Authentication

### API Key Authentication
```http
GET /api/v1/projects
Authorization: Bearer <api_key>
```

### API Key Management
```http
# Create API Key
POST /api/v1/api_keys
{
  "name": "Production App",
  "scopes": ["read:prompts", "write:prompts"]
}

# Response
{
  "api_key": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Production App",
    "key": "ank_live_1234567890abcdef",
    "scopes": ["read:prompts", "write:prompts"],
    "created_at": "2025-07-24T10:00:00Z"
  }
}
```

## Core Resources

### Projects

#### List Projects
```http
GET /api/v1/projects

Response:
{
  "projects": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Customer Service",
      "slug": "customer-service",
      "description": "Prompts for customer support",
      "organisation_id": "660e8400-e29b-41d4-a716-446655440000",
      "created_at": "2025-07-24T10:00:00Z",
      "updated_at": "2025-07-24T10:00:00Z"
    }
  ],
  "meta": {
    "cursor": "eyJpZCI6IjU1MGU4NDAwLWUyOWItNDFkNC1hNzE2LTQ0NjY1NTQ0MDAwMCJ9",
    "has_more": false
  }
}
```

#### Get Project
```http
GET /api/v1/projects/{id}
GET /api/v1/projects/by_slug/{slug}
```

#### Create Project
```http
POST /api/v1/projects
{
  "project": {
    "name": "Customer Service",
    "description": "Prompts for customer support"
  }
}
```

#### Update Project
```http
PATCH /api/v1/projects/{id}
{
  "project": {
    "description": "Updated description"
  }
}
```

#### Delete Project
```http
DELETE /api/v1/projects/{id}
```

### Prompt Sets

#### List Prompt Sets
```http
GET /api/v1/projects/{project_id}/prompt_sets
GET /api/v1/prompt_sets?project_id={project_id}
```

#### Get Prompt Set
```http
GET /api/v1/prompt_sets/{id}
GET /api/v1/prompt_sets/by_address/{project_slug}/{prompt_set_slug}
```

#### Create Prompt Set
```http
POST /api/v1/projects/{project_id}/prompt_sets
{
  "prompt_set": {
    "name": "Email Templates",
    "description": "Customer email responses"
  }
}
```

### Prompts

#### List Prompts
```http
GET /api/v1/prompt_sets/{prompt_set_id}/prompts
```

#### Get Prompt
```http
GET /api/v1/prompts/{id}
GET /api/v1/prompts/by_address/{project_slug}/{prompt_set_slug}/{prompt_slug}

Response:
{
  "prompt": {
    "id": "770e8400-e29b-41d4-a716-446655440000",
    "name": "Welcome Email",
    "slug": "welcome-email",
    "description": "New user welcome message",
    "template": "Hello {{ customer_name }},\n\nWelcome to {{ company_name }}!",
    "parameters": [
      {
        "name": "customer_name",
        "type": "string",
        "description": "Customer's full name",
        "required": true
      },
      {
        "name": "company_name",
        "type": "string",
        "description": "Company name",
        "required": true,
        "default": "Acme Corp"
      }
    ],
    "created_at": "2025-07-24T10:00:00Z",
    "updated_at": "2025-07-24T10:00:00Z"
  }
}
```

#### Create Prompt
```http
POST /api/v1/prompt_sets/{prompt_set_id}/prompts
{
  "prompt": {
    "name": "Welcome Email",
    "template": "Hello {{ customer_name }},\n\nWelcome!",
    "parameters": [
      {
        "name": "customer_name",
        "type": "string",
        "required": true
      }
    ]
  }
}
```

#### Render Prompt
```http
POST /api/v1/prompts/{id}/render
{
  "variables": {
    "customer_name": "John Doe",
    "company_name": "Acme Corp"
  }
}

Response:
{
  "rendered": "Hello John Doe,\n\nWelcome to Acme Corp!",
  "metadata": {
    "template_version": "1.0",
    "rendered_at": "2025-07-24T10:00:00Z"
  }
}
```

### Versions

#### List Versions
```http
GET /api/v1/prompt_sets/{prompt_set_id}/versions

Response:
{
  "versions": [
    {
      "id": "880e8400-e29b-41d4-a716-446655440000",
      "label": "v1.0.0",
      "created_at": "2025-07-24T10:00:00Z",
      "created_by": {
        "id": "990e8400-e29b-41d4-a716-446655440000",
        "email": "user@example.com"
      }
    }
  ]
}
```

#### Get Version
```http
GET /api/v1/versions/{id}
GET /api/v1/prompt_sets/{prompt_set_id}/versions/{label}
```

#### Create Version
```http
POST /api/v1/prompt_sets/{prompt_set_id}/versions
{
  "version": {
    "label": "v1.0.0",
    "description": "Initial release"
  }
}
```

### Organisations

#### Get Current Organisation
```http
GET /api/v1/organisation
```

#### List Members
```http
GET /api/v1/organisation/members
```

#### Invite Member
```http
POST /api/v1/organisation/members
{
  "member": {
    "email": "newuser@example.com",
    "role": "member"
  }
}
```

## SDK Design

### Elixir SDK

#### Installation
```elixir
# mix.exs
def deps do
  [
    {:anvil_sdk, "~> 1.0"}
  ]
end
```

#### Configuration
```elixir
# config/config.exs
config :anvil_sdk,
  api_key: System.get_env("ANVIL_API_KEY"),
  base_url: "https://anvil.example.com/api/v1"
```

#### Usage
```elixir
# Fetch a prompt
{:ok, prompt} = Anvil.get("customer-service/emails/welcome")

# Render with variables
{:ok, rendered} = Anvil.render(prompt, %{
  customer_name: "John Doe",
  company_name: "Acme Corp"
})

# Version-specific fetch
{:ok, prompt} = Anvil.get("customer-service/emails@v1.0.0")

# With caching
{:ok, prompt} = Anvil.get("customer-service/emails/welcome", 
  cache: true,
  ttl: 3600
)
```

### JavaScript/TypeScript SDK

#### Installation
```bash
npm install @anvil/sdk
```

#### Usage
```typescript
import { Anvil } from '@anvil/sdk';

const anvil = new Anvil({
  apiKey: process.env.ANVIL_API_KEY,
  baseUrl: 'https://anvil.example.com/api/v1'
});

// Fetch a prompt
const prompt = await anvil.prompts.get('customer-service/emails/welcome');

// Render with variables
const rendered = await anvil.prompts.render(prompt.id, {
  customer_name: 'John Doe',
  company_name: 'Acme Corp'
});

// Live updates
anvil.prompts.subscribe('customer-service/emails/welcome', (prompt) => {
  console.log('Prompt updated:', prompt);
});
```

## Error Responses

### Error Format
```json
{
  "error": {
    "type": "validation_error",
    "message": "Validation failed",
    "details": [
      {
        "field": "template",
        "message": "Invalid Liquid syntax"
      }
    ]
  }
}
```

### Standard Error Types
- `authentication_error`: Invalid or missing API key
- `authorization_error`: Insufficient permissions
- `validation_error`: Invalid request data
- `not_found_error`: Resource not found
- `rate_limit_error`: Too many requests
- `server_error`: Internal server error

### HTTP Status Codes
- `200 OK`: Successful request
- `201 Created`: Resource created
- `204 No Content`: Successful deletion
- `400 Bad Request`: Invalid request
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation failed
- `429 Too Many Requests`: Rate limited
- `500 Internal Server Error`: Server error

## Rate Limiting

### Headers
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1627849200
```

### Limits
- Standard: 1,000 requests per hour
- Rendering: 10,000 requests per hour
- Bulk operations: 100 requests per hour

## Pagination

### Cursor-Based
```http
GET /api/v1/projects?cursor=eyJpZCI6IjEyMzQifQ==&limit=20

Response:
{
  "data": [...],
  "meta": {
    "cursor": "eyJpZCI6IjU2NzgifQ==",
    "has_more": true
  }
}
```

## Webhooks (Future)

### Event Types
- `prompt.created`
- `prompt.updated`
- `prompt.deleted`
- `version.created`
- `member.invited`
- `member.removed`

### Webhook Payload
```json
{
  "id": "evt_1234567890",
  "type": "prompt.updated",
  "created_at": "2025-07-24T10:00:00Z",
  "data": {
    "prompt": { ... }
  }
}
```

## Best Practices

1. **Caching**: Use ETags for conditional requests
2. **Compression**: Accept gzip encoding
3. **Retries**: Implement exponential backoff
4. **Timeouts**: Set reasonable client timeouts
5. **Versioning**: Always specify API version
6. **Error Handling**: Parse error details
7. **Security**: Never expose API keys in client code