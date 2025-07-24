---
verblock: "2025-07-24:v1.0: matts - Initial chapter creation"
---
# 7. Security

## Security Philosophy

Anvil implements defence-in-depth security, treating every layer of the application as a potential attack surface. Security is not an afterthought but a core design principle integrated throughout the system.

## Authentication

### Password Authentication

#### Implementation
```elixir
# Using Argon2 via phx_gen_auth
config :argon2_elixir,
  t_cost: 1,
  m_cost: 32768,
  parallelism: 1,
  salt_len: 16,
  hash_len: 32
```

#### Password Requirements
- Minimum 12 characters
- No maximum length (within reason)
- No complexity requirements (length is key)
- Stored using Argon2id hashing
- Never logged or transmitted in plain text

### Magic Link Authentication

#### Flow
1. User requests magic link with email
2. System generates cryptographically secure token
3. Token stored with 15-minute expiration
4. Email sent with signed link
5. Link validates token and creates session
6. Token immediately invalidated after use

#### Security Measures
- Tokens are single-use
- Short expiration window
- Rate limiting on requests
- Secure random generation
- HMAC signed URLs

### API Key Authentication

#### Key Format
```
ank_[environment]_[random_string]

Examples:
ank_live_1a2b3c4d5e6f7g8h9i0j
ank_test_9z8y7x6w5v4u3t2s1r0q
```

#### Key Storage
- Only hash stored in database
- Key shown once on creation
- Cannot be retrieved after creation
- Scoped permissions per key

### Session Management

#### Configuration
```elixir
# 30-day remember me, 2-hour idle timeout
config :anvil, AnvilWeb.Endpoint,
  session_options: [
    store: :cookie,
    key: "_anvil_key",
    signing_salt: "...",
    encryption_salt: "...",
    same_site: "Lax",
    secure: true,
    http_only: true,
    max_age: 30 * 24 * 60 * 60
  ]
```

#### Security Features
- HTTPOnly cookies prevent JS access
- Secure flag ensures HTTPS only
- SameSite prevents CSRF
- Encrypted session data
- Automatic renewal on activity

## Authorisation

### Policy-Based Access Control

#### Ash Policy Implementation
```elixir
defmodule Anvil.Projects.Project do
  policies do
    # Bypass for read - check org membership
    bypass action_type(:read) do
      authorize_if expr(
        exists(organisation.memberships, user_id == ^actor(:id))
      )
    end
    
    # Only org owners/admins can create
    policy action_type(:create) do
      authorize_if expr(
        exists(organisation.memberships, 
          user_id == ^actor(:id) and role in [:owner, :admin]
        )
      )
    end
  end
end
```

### Role Hierarchy

```
Owner
 ├── All permissions
 ├── Manage organisation
 ├── Manage members
 └── Delete organisation

Admin  
 ├── Manage projects
 ├── Manage prompts
 └── View members

Member
 ├── View projects
 ├── Create/edit prompts
 └── View prompts
```

### Data Isolation

#### Organisation Boundaries
- All queries filtered by organisation context
- No cross-organisation data access
- Personal organisations protected
- Policies enforced at data layer

## Input Validation

### Template Validation

```elixir
def validate_template(template) do
  # Prevent script injection
  forbidden_tags = ~w[script iframe object embed]
  
  # Validate Liquid syntax
  case Solid.parse(template) do
    {:ok, _} -> 
      if contains_forbidden_tags?(template, forbidden_tags) do
        {:error, "Template contains forbidden HTML tags"}
      else
        :ok
      end
    {:error, error} -> 
      {:error, "Invalid Liquid syntax: #{error}"}
  end
end
```

### Parameter Validation

```elixir
# Type validation
defmodule Anvil.Types.ParameterList do
  def validate_parameter(%{"type" => type, "name" => name}) do
    cond do
      type not in ["string", "number", "boolean"] ->
        {:error, "Invalid parameter type"}
      
      not Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, name) ->
        {:error, "Invalid parameter name"}
      
      true ->
        :ok
    end
  end
end
```

### SQL Injection Prevention

- Ecto parameterised queries
- No raw SQL construction
- Input sanitisation
- Prepared statements

## Encryption

### Data at Rest

```sql
-- PostgreSQL transparent encryption
CREATE TABLE sensitive_data (
  id UUID PRIMARY KEY,
  encrypted_content BYTEA
) WITH (encryption_key_id = 'anvil-encryption-key');
```

### Data in Transit

#### TLS Configuration
```elixir
config :anvil, AnvilWeb.Endpoint,
  force_ssl: [
    hsts: true,
    expires: 31536000,
    preload: true,
    rewrite_on: [:x_forwarded_proto]
  ]
```

#### Certificate Management
- Let's Encrypt auto-renewal
- TLS 1.2 minimum
- Strong cipher suites only
- HSTS enforcement

## API Security

### Rate Limiting

```elixir
defmodule AnvilWeb.RateLimiter do
  use GenServer
  
  @limits %{
    api_standard: {1000, :hour},
    api_render: {10000, :hour},
    auth_attempts: {5, :minute},
    magic_link: {3, :hour}
  }
  
  def check_rate(key, action) do
    {limit, window} = @limits[action]
    # Implementation using Redis or ETS
  end
end
```

### CORS Configuration

```elixir
plug Corsica,
  origins: [
    "http://localhost:3000",
    ~r{^https://([\w-]+\.)?anvil\.com$}
  ],
  allow_credentials: true,
  allow_headers: ["content-type", "authorization"],
  max_age: 86400
```

## Web Security

### CSRF Protection

```elixir
# Automatic in Phoenix
plug :protect_from_forgery

# Template usage
<%= csrf_meta_tag() %>
<form>
  <%= csrf_input_tag() %>
</form>
```

### Content Security Policy

```elixir
plug :put_secure_browser_headers, %{
  "content-security-policy" => "
    default-src 'self';
    script-src 'self' 'unsafe-inline' 'unsafe-eval';
    style-src 'self' 'unsafe-inline';
    img-src 'self' data: https:;
    font-src 'self';
    connect-src 'self' wss://#{host};
  "
}
```

### XSS Prevention

- Automatic HTML escaping in templates
- Sanitisation of user content
- CSP headers
- No inline scripts
- Template validation

## Audit Logging

### Events Logged

```elixir
defmodule Anvil.Audit do
  @events [
    # Authentication
    :user_login,
    :user_logout,
    :failed_login,
    :password_reset,
    
    # Authorisation
    :permission_denied,
    :role_changed,
    
    # Data Access
    :prompt_created,
    :prompt_updated,
    :prompt_deleted,
    :version_created,
    
    # Administration
    :member_invited,
    :member_removed,
    :organisation_updated
  ]
end
```

### Log Format

```json
{
  "timestamp": "2025-07-24T10:00:00Z",
  "event": "prompt_updated",
  "actor_id": "550e8400-e29b-41d4-a716-446655440000",
  "actor_email": "user@example.com",
  "resource_type": "prompt",
  "resource_id": "660e8400-e29b-41d4-a716-446655440000",
  "organisation_id": "770e8400-e29b-41d4-a716-446655440000",
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "changes": {
    "template": "[REDACTED]"
  }
}
```

## Vulnerability Management

### Dependency Scanning

```bash
# Mix audit for Elixir deps
mix deps.audit

# npm audit for JS deps
npm audit

# Automated in CI/CD
```

### Security Headers

```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

## Incident Response

### Response Plan

1. **Detection**: Monitoring alerts
2. **Assessment**: Severity determination
3. **Containment**: Isolate affected systems
4. **Eradication**: Remove threat
5. **Recovery**: Restore services
6. **Lessons**: Post-mortem analysis

### Security Contacts

```
Security Team: security@anvil.com
Emergency: +1-555-SEC-URITY
Bug Bounty: https://anvil.com/security
```

## Compliance

### Data Protection

- GDPR compliance for EU users
- Right to deletion
- Data portability
- Privacy by design
- Minimal data collection

### Security Standards

- OWASP Top 10 mitigation
- NIST Cybersecurity Framework
- SOC 2 Type II (planned)
- ISO 27001 alignment

## Security Checklist

### Development
- [ ] Input validation on all user data
- [ ] Output encoding for XSS prevention
- [ ] Parameterised database queries
- [ ] Authentication on all endpoints
- [ ] Authorisation checks enforced
- [ ] Sensitive data encrypted
- [ ] Security headers configured
- [ ] Dependencies up to date

### Deployment
- [ ] HTTPS enforced
- [ ] Secrets in environment variables
- [ ] Database encryption enabled
- [ ] Firewall rules configured
- [ ] Monitoring alerts set up
- [ ] Backup encryption verified
- [ ] Incident response tested
- [ ] Security scan completed