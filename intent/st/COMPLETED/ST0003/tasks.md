# Tasks - ST0003: Organisations own projects

## Completed Tasks

### Core Implementation
- [x] Create Organisation resource with Ash
- [x] Create Membership join table resource
- [x] Update Project to belong to Organisation
- [x] Create database migration
- [x] Implement role-based authorization policies
- [x] Add unique constraints for slugs and memberships

### Authorization
- [x] Read policies for organisation members
- [x] Create policies with custom checks
- [x] Update/destroy policies for admins/owners
- [x] Prevent deletion of personal organisations

### Data Migration
- [x] Personal organisations are automatically created for new users
- [x] Owner memberships are automatically created
- [x] Projects properly reference organisations
- [x] Seed data updated to create organisations

### User Interface
- [x] Create organisation switcher component
- [x] Add organisation context to LiveViews
- [x] Build organisation management pages (list, create, show)
- [x] Implement member invitation flow
- [x] Add role management UI
- [x] Update project creation to use current organisation

### User Registration Flow
- [x] Auto-create personal organisation on user registration
- [x] Set up initial owner membership via CreateOwnerMembership change
- [x] Ensure personal organisation for invited users on first login

### API Updates
- [x] Add organisation context to all queries
- [x] Update project operations to respect organisation ownership
- [x] Organisation management through LiveView actions
- [x] Implement invitation system via custom action

### Implementation Details
- [x] GenerateSlug change for URL-friendly identifiers
- [x] CreatePersonalOrganisation change for automatic personal org creation
- [x] UserCanManageOrganisation policy check for membership creation
- [x] ListUserOrganisations query module for efficient loading
- [x] OrganisationHelper utilities for role checking
- [x] OrganisationAware behaviour for LiveView integration

## Known Issues

### Minor Items
- [ ] Migration filename has typo (orgainisations -> organisations) - cosmetic only
- [ ] Organisation switcher currently reloads page instead of updating session directly

## Task Notes

### Priority Order
1. **Data Migration** - Critical for existing data
2. **Registration Flow** - Needed for new users
3. **Organisation Switcher** - Core UX component
4. **Management Pages** - Enable org administration
5. **Testing** - Ensure reliability

### UI Component Requirements

**Organisation Switcher**:
- Dropdown showing user's organisations
- Visual indicator for current org
- Quick switch functionality
- Link to create new org

**Invitation Flow**:
- Email-based invitations
- Role selection during invite
- Acceptance/rejection handling
- Notification system

## Dependencies

### Technical Dependencies
- ST0001 must be substantially complete (✓)
- User authentication system in place (✓)
- LiveView navigation structure (✓)

### Migration Dependencies
- Backup existing data before migration
- Plan downtime window if needed
- Test migration on staging first

### Feature Dependencies
- Organisation switcher blocks most other UI work
- Invitation system needs email infrastructure
- API updates should follow UI implementation