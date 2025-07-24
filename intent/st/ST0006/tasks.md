# Tasks - ST0006: Testing Core Functionality

## Phase 1: Testing Infrastructure Setup

### Dependencies and Configuration

- [ ] Add test dependencies to mix.exs
  - [ ] {:phoenix_test, "~> 0.4.0", only: :test, runtime: false}
  - [ ] {:ex_machina, "~> 2.8", only: :test}
  - [ ] {:faker, "~> 0.18", only: :test}
- [ ] Configure test environment in config/test.exs
  - [ ] Ensure Ecto sandbox mode
  - [ ] Disable external services (email, etc.)
  - [ ] Set up test-specific Ash configuration

### Test Support Files

- [ ] Enhance test/support/data_case.ex
  - [ ] Import Ecto.Query
  - [ ] Import Ash test helpers
  - [ ] Add generator imports
  - [ ] Add factory imports
- [ ] Create test/support/feature_case.ex
  - [ ] Set up PhoenixTest
  - [ ] Add authentication helpers
  - [ ] Add navigation helpers
  - [ ] Add assertion helpers
- [ ] Create test/support/integration_helpers.ex
  - [ ] sign_in_user/2 function
  - [ ] create_user_with_org/0 function
  - [ ] create_project_for_user/1 function
  - [ ] Common test data setup functions

### Generator Setup

- [ ] Create test/support/generators.ex
  - [ ] Configure Ash.Generator
  - [ ] Define resource generators
- [ ] Create test/support/factories/accounts_factory.ex
  - [ ] User factory with email sequence
  - [ ] Token factory
  - [ ] API key factory
- [ ] Create test/support/factories/organisations_factory.ex
  - [ ] Organisation factory
  - [ ] Membership factory
  - [ ] Personal organisation helper
- [ ] Create test/support/factories/prompts_factory.ex
  - [ ] Project factory
  - [ ] PromptSet factory
  - [ ] Prompt factory with valid template
  - [ ] Version factory

## Phase 2: Unit Tests - Ash Resources

### Accounts Domain Tests

- [ ] Create test/anvil/accounts/user_test.exs
  - [ ] User creation with validations
  - [ ] Password authentication
  - [ ] Magic link generation
  - [ ] Personal org auto-creation
- [ ] Create test/anvil/accounts/token_test.exs
  - [ ] Token generation
  - [ ] Token validation
  - [ ] Token expiration

### Organisations Domain Tests

- [ ] Create test/anvil/organisations/organisation_test.exs
  - [ ] Organisation creation
  - [ ] Slug generation and uniqueness
  - [ ] Personal org protection
- [ ] Create test/anvil/organisations/membership_test.exs
  - [ ] Membership creation
  - [ ] Role validation
  - [ ] Unique user/org constraint

### Projects Domain Tests

- [ ] Create test/anvil/projects/project_test.exs
  - [ ] Project creation within org
  - [ ] Name/slug uniqueness within org
  - [ ] Organisation relationship

### Prompts Domain Tests

- [ ] Create test/anvil/prompts/prompt_set_test.exs
  - [ ] PromptSet creation
  - [ ] Project relationship
  - [ ] Name uniqueness within project
- [ ] Create test/anvil/prompts/prompt_test.exs
  - [ ] Prompt creation with template
  - [ ] Liquid syntax validation
  - [ ] Parameter extraction
  - [ ] Parameter validation
- [ ] Create test/anvil/prompts/version_test.exs
  - [ ] Version creation
  - [ ] Immutability
  - [ ] Snapshot accuracy

### Policy Tests

- [ ] Create test/anvil/policies/organisation_policy_test.exs
  - [ ] Member can read org
  - [ ] Only owner can update/delete
  - [ ] Personal org cannot be deleted
- [ ] Create test/anvil/policies/project_policy_test.exs
  - [ ] Only org members can access
  - [ ] Role-based permissions
- [ ] Create test/anvil/policies/cross_org_isolation_test.exs
  - [ ] No access to other org's resources
  - [ ] Complete data isolation

## Phase 3: Integration Tests - LiveView Flows

### Authentication Tests

- [ ] Create test/anvil_web/integration/auth/sign_up_test.exs
  - [ ] Successful registration
  - [ ] Email validation
  - [ ] Password requirements
  - [ ] Personal org creation
- [ ] Create test/anvil_web/integration/auth/sign_in_test.exs
  - [ ] Password sign in
  - [ ] Invalid credentials
  - [ ] Session creation
- [ ] Create test/anvil_web/integration/auth/magic_link_test.exs
  - [ ] Request magic link
  - [ ] Valid link usage
  - [ ] Expired link handling

### Dashboard Tests

- [ ] Create test/anvil_web/integration/dashboard/dashboard_smoke_test.exs
  - [ ] Dashboard loads
  - [ ] Shows user's organisations
  - [ ] Shows recent activity
  - [ ] Navigation works

### Organisation Management Tests

- [ ] Create test/anvil_web/integration/organisations/organisation_management_test.exs
  - [ ] Create new organisation
  - [ ] Switch between organisations
  - [ ] Update organisation details
  - [ ] Cannot delete personal org
- [ ] Create test/anvil_web/integration/organisations/member_invitation_test.exs
  - [ ] Invite new member by email
  - [ ] Existing user invitation
  - [ ] New user invitation with account creation
  - [ ] Role assignment

### Project Tests

- [ ] Create test/anvil_web/integration/projects/project_crud_test.exs
  - [ ] Create project in current org
  - [ ] List projects
  - [ ] Update project
  - [ ] Delete project

### Prompt Management Tests

- [ ] Create test/anvil_web/integration/prompts/prompt_smoke_test.exs
  - [ ] Navigate to prompts
  - [ ] List prompt sets
  - [ ] Basic UI elements present
- [ ] Create test/anvil_web/integration/prompts/prompt_functional_test.exs
  - [ ] Complete prompt creation flow
  - [ ] Template validation feedback
  - [ ] Parameter management
  - [ ] Version creation

## Phase 4: API Tests

### Health Check

- [ ] Create test/anvil_web/api/health_check_test.exs
  - [ ] Health endpoint returns 200
  - [ ] Database connectivity check
  - [ ] Response format

### Prompt API

- [ ] Create test/anvil_web/api/prompt_api_test.exs
  - [ ] API key authentication
  - [ ] Get prompt by ID
  - [ ] Get prompt by address
  - [ ] Render prompt with variables
  - [ ] Invalid API key handling
  - [ ] Rate limiting

## Phase 5: Test Utilities and CI/CD

### Test Utilities

- [ ] Create mix test.unit alias for unit tests only
- [ ] Create mix test.integration alias for integration tests
- [ ] Add test coverage reporting with ExCoveralls
- [ ] Configure test matrix for different Elixir/OTP versions

### CI/CD Integration

- [ ] Create .github/workflows/test.yml
  - [ ] Set up Elixir/OTP
  - [ ] Set up PostgreSQL service
  - [ ] Run formatter check
  - [ ] Run Credo
  - [ ] Run tests with coverage
  - [ ] Upload coverage to Codecov
- [ ] Add test status badge to README
- [ ] Configure branch protection rules

## Phase 6: Documentation and Examples

### Test Documentation

- [ ] Update ST0006 impl.md with examples
- [ ] Create testing guide in docs/
- [ ] Document test data generation patterns
- [ ] Document common test scenarios

### Developer Guide

- [ ] How to run tests locally
- [ ] How to debug failing tests
- [ ] How to add new test cases
- [ ] Testing best practices

## Task Notes

### Priority Order

1. Infrastructure setup (Phase 1) - Required for all other tests
2. Unit tests (Phase 2) - Fast feedback, core functionality
3. Integration tests (Phase 3) - User-facing features
4. API tests (Phase 4) - External interface
5. CI/CD (Phase 5) - Automation
6. Documentation (Phase 6) - Knowledge sharing

### Key Considerations

- Start with the most critical paths (auth, org isolation)
- Ensure tests are independent and can run in any order
- Keep tests fast - mock external services
- Use descriptive test names that explain the scenario
- Follow AAA pattern: Arrange, Act, Assert

## Dependencies

### Technical Dependencies

- PhoenixTest requires Phoenix 1.7+
- Ash.Generator requires Ash 3.0+
- ExMachina works with Ecto 3.0+

### Knowledge Dependencies

- Understanding of Ash policies and actions
- Phoenix LiveView testing patterns
- Ecto sandbox usage

### Completion Dependencies

- Phase 1 must be complete before other phases
- Unit tests can be written in parallel
- Integration tests depend on test infrastructure
- CI/CD depends on having tests to run
