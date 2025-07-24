# Design - ST0006: Testing Core Functionality

## Approach

Anvil's testing strategy follows a pyramid approach with comprehensive coverage across unit, integration, and end-to-end tests. The implementation draws heavily from MeetZaya's proven patterns while adapting to Anvil's specific needs with Ash Framework and Phoenix LiveView.

### Testing Philosophy

1. **Test Behaviour, Not Implementation**: Focus on user-facing functionality
2. **Fast Feedback**: Unit tests run in milliseconds, integration in seconds
3. **Isolated Tests**: Each test is independent with fresh data
4. **Living Documentation**: Tests serve as usage examples
5. **Policy Verification**: Ensure authorisation rules are enforced

### Testing Stack

- **ExUnit**: Core testing framework
- **PhoenixTest**: Browser-like integration testing
- **Ash.Generator**: Test data generation
- **Ecto.Sandbox**: Database isolation
- **ExMachina**: Factory pattern implementation

## Design Decisions

### 1. Test Organization

**Decision**: Separate unit and integration tests into distinct directories
**Rationale**: 
- Clear separation of concerns
- Different helper requirements
- Easier to run subsets of tests
- Follows MeetZaya's proven pattern

### 2. PhoenixTest for Integration

**Decision**: Use PhoenixTest instead of Wallaby for integration tests
**Rationale**:
- No external dependencies (ChromeDriver, etc.)
- Faster execution
- Better LiveView support
- Simpler CI/CD setup

### 3. Ash.Generator for Test Data

**Decision**: Use Ash.Generator for creating test resources
**Rationale**:
- Respects Ash validations and policies
- Handles complex relationships
- Consistent with production code paths
- Better than raw Ecto inserts

### 4. Policy Testing Strategy

**Decision**: Test policies through actual operations, not in isolation
**Rationale**:
- Ensures policies work in real scenarios
- Tests the full stack
- Catches integration issues
- More maintainable

## Architecture

### Test Infrastructure

```
┌─────────────────────────────────────────────────────┐
│                   Test Helpers                      │
├─────────────┬──────────────┬──────────────┬────────┤
│  DataCase   │ FeatureCase  │ Generators   │ Helpers│
├─────────────┴──────────────┴──────────────┴────────┤
│                    ExUnit                           │
├─────────────────────────────────────────────────────┤
│               Ecto.Sandbox                          │
└─────────────────────────────────────────────────────┘
```

### Test Case Hierarchy

```
ExUnit.CaseTemplate
├── DataCase
│   ├── Ecto.Sandbox checkout
│   ├── Ash.Generator imports
│   ├── Factory imports
│   └── Resource helpers
└── FeatureCase
    ├── PhoenixTest setup
    ├── Authentication helpers
    ├── Navigation helpers
    └── Assertion helpers
```

### Test Data Flow

```
Generator.create_user()
    │
    ├─> Ash.Generator
    │     └─> Validates with Ash
    │
    ├─> Creates personal org
    │     └─> Via Ash hooks
    │
    └─> Returns user with relations
```

### Integration Test Flow

```
FeatureCase
    │
    ├─> sign_in_user(conn, user)
    │     ├─> POST to /sign-in
    │     └─> Follow redirects
    │
    ├─> visit(conn, path)
    │     └─> PhoenixTest navigation
    │
    └─> assert_has(selector)
          └─> DOM assertions
```

## Directory Structure

```
test/
├── anvil/                           # Unit tests
│   ├── accounts/
│   │   ├── user_test.exs
│   │   └── token_test.exs
│   ├── organisations/
│   │   ├── organisation_test.exs
│   │   └── membership_test.exs
│   ├── projects/
│   │   └── project_test.exs
│   └── prompts/
│       ├── prompt_set_test.exs
│       ├── prompt_test.exs
│       └── version_test.exs
├── anvil_web/
│   ├── integration/                 # PhoenixTest integration
│   │   ├── auth/
│   │   │   ├── sign_in_test.exs
│   │   │   └── sign_up_test.exs
│   │   ├── dashboard/
│   │   │   └── dashboard_smoke_test.exs
│   │   ├── organisations/
│   │   │   ├── organisation_management_test.exs
│   │   │   └── member_invitation_test.exs
│   │   ├── projects/
│   │   │   └── project_crud_test.exs
│   │   └── prompts/
│   │       ├── prompt_smoke_test.exs
│   │       └── prompt_functional_test.exs
│   └── api/
│       ├── prompt_api_test.exs
│       └── health_check_test.exs
└── support/
    ├── data_case.ex                 # Enhanced for Ash
    ├── feature_case.ex              # New PhoenixTest case
    ├── integration_helpers.ex       # Common utilities
    ├── generators.ex                # Ash.Generator setup
    └── factories/
        ├── accounts_factory.ex
        ├── organisations_factory.ex
        └── prompts_factory.ex
```

## Test Categories

### 1. Unit Tests (70%)

**Focus**: Individual Ash resources and actions
**Examples**:
- Resource validations
- Calculated attributes
- Custom actions
- Policy enforcement

### 2. Integration Tests (25%)

**Focus**: User flows through the UI
**Examples**:
- Complete CRUD workflows
- Authentication flows
- Cross-resource operations
- LiveView interactions

### 3. API Tests (5%)

**Focus**: REST API endpoints
**Examples**:
- Prompt retrieval
- Authentication
- Error responses
- Rate limiting

## Key Test Scenarios

### Authentication & Authorization
1. User registration with personal org creation
2. Sign in via password and magic link
3. API key generation and usage
4. Session management

### Multi-tenancy
1. Organisation creation and switching
2. Member invitation and role management
3. Data isolation between organisations
4. Personal organisation protection

### Prompt Management
1. Project creation within organisation
2. Prompt set and prompt CRUD
3. Template validation with Liquid
4. Parameter management
5. Version creation and retrieval

### Policy Enforcement
1. Cross-organisation access denial
2. Role-based permissions
3. Personal data protection
4. API key scoping

## Implementation Patterns

### Test Data Generation

```elixir
# Using Ash.Generator
user = Generator.create_user()
org = Generator.create_organisation(owner: user)
project = Generator.create_project(organisation: org)

# With factories
user = insert(:user)
org = insert(:organisation, owner: user)
```

### Integration Test Pattern

```elixir
describe "prompt management" do
  setup [:register_and_log_in_user]
  
  test "creates a new prompt", %{conn: conn, user: user} do
    project = create_project_for_user(user)
    
    conn
    |> visit(~p"/projects/#{project.id}/prompts")
    |> click_link("New Prompt")
    |> fill_in("Name", with: "Welcome Email")
    |> fill_in("Template", with: "Hello {{ name }}")
    |> click_button("Save")
    |> assert_has("Prompt created successfully")
  end
end
```

### Policy Test Pattern

```elixir
test "prevents access to other org's resources" do
  user1 = create_user_with_org()
  user2 = create_user_with_org()
  project = create_project(user1.personal_org)
  
  assert {:error, %Ash.Error.Forbidden{}} = 
    Projects.get_project(project.id, actor: user2)
end
```

## Alternatives Considered

### 1. Wallaby for Integration Testing

**Pros**: Real browser testing, JavaScript support
**Cons**: External dependencies, slower, complex setup
**Decision**: Use PhoenixTest for simpler, faster tests

### 2. Direct Ecto Inserts for Test Data

**Pros**: Faster, simpler
**Cons**: Bypasses validations, doesn't test real paths
**Decision**: Use Ash.Generator for realistic data

### 3. Mocking Ash Policies

**Pros**: Faster tests, isolated units
**Cons**: Doesn't test real integration, complex setup
**Decision**: Test policies through actual operations

### 4. Single Test Case

**Pros**: Simpler setup, less code
**Cons**: Mixed concerns, harder to maintain
**Decision**: Separate DataCase and FeatureCase for clarity