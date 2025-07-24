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

## Remaining Tasks

### Data Migration
- [ ] Create migration script for existing projects
- [ ] Generate personal organisations for existing users
- [ ] Transfer project ownership to personal orgs
- [ ] Create owner memberships for users
- [ ] Fix typo in migration filename (orgainisations -> organisations)

### User Interface
- [ ] Create organisation switcher component
- [ ] Add organisation context to LiveViews
- [ ] Build organisation management pages (list, create, edit)
- [ ] Implement member invitation flow
- [ ] Add role management UI
- [ ] Update project creation to select organisation

### User Registration Flow
- [ ] Auto-create personal organisation on user registration
- [ ] Set up initial owner membership
- [ ] Update seed data to create orgs

### API Updates
- [ ] Add organisation context to API calls
- [ ] Update project endpoints to require org context
- [ ] Add organisation management endpoints
- [ ] Implement invitation API

### Testing
- [ ] Unit tests for Organisation resource
- [ ] Unit tests for Membership resource
- [ ] Integration tests for authorization policies
- [ ] End-to-end tests for organisation workflows

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