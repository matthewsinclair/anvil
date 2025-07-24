# Results - ST0003: Organisations own projects

## Results

Partially implemented organisation-based ownership model. The backend infrastructure is complete with database schema, Ash resources, and authorization policies. However, the user interface and data migration components are not yet implemented, making this feature not yet usable in production.

## Outcomes

### Successfully Implemented

1. **Data Layer**
   - Created organisations table with proper constraints
   - Implemented membership join table with roles
   - Migrated projects from user to organisation ownership
   - Added cascading delete rules for data integrity

2. **Domain Model**
   - Organisation resource with CRUD operations
   - Membership resource with role management
   - Updated Project resource relationships
   - Three-tier role system (owner, admin, member)

3. **Authorization**
   - Role-based policies for all resources
   - Custom checks for create operations
   - Personal organisation protection
   - Proper permission inheritance

### Not Completed

1. **User Experience**
   - No UI for organisation management
   - No organisation context in navigation
   - No way to switch between organisations
   - No invitation system

2. **Integration**
   - User registration doesn't create personal orgs
   - Existing data not migrated
   - API endpoints not updated
   - No organisation selection in project creation

## Metrics

- **Backend Completion**: 90% (missing data migration script)
- **Frontend Completion**: 0% (no UI components built)
- **Overall Feature Completion**: ~40%
- **Tables Added**: 2 (organisations, organisation_memberships)
- **Tables Modified**: 1 (projects)
- **Policy Rules Added**: 12
- **Lines of Code**: ~500 (resources, migrations, checks)

## Lessons Learned

### Positive Discoveries

1. **Ash Framework Flexibility**: Custom policy checks solved the create action authorization challenge elegantly.

2. **Personal Organisation Pattern**: This design choice simplified many edge cases and provides a clean upgrade path.

3. **Simple Role Model**: Three roles are sufficient and avoid over-engineering.

### Challenges Encountered

1. **Create Action Policies**: Ash can't traverse relationships during create, requiring workaround with custom checks.

2. **Migration Complexity**: The schema migration was complex due to foreign key dependencies and column renames.

3. **Testing Gap**: Without UI, it's difficult to verify the authorization policies work correctly in practice.

### Process Improvements Needed

1. **Vertical Slicing**: Should have built minimal UI alongside backend to validate design.

2. **Migration Scripts**: Data migration should be written with schema migration.

3. **Documentation**: Design decisions should be documented as they're made.

## Follow-up Work

### Immediate (Blocking Progress)

1. **Organisation Switcher Component**: Essential for any multi-org functionality
2. **Update User Registration**: Auto-create personal organisations
3. **Basic Organisation Pages**: At least list and show pages

### Short-term (Next Sprint)

1. **Project Creation Update**: Add organisation selection
2. **Migration Script**: For existing user data
3. **Invitation System**: Basic email invitations
4. **Role Management UI**: Change member roles

### Long-term (Future Enhancement)

1. **Advanced Permissions**: More granular project-level permissions
2. **Organisation Settings**: Customization options
3. **Billing Integration**: Connect payment per organisation
4. **Audit Logs**: Track organisation changes
5. **SSO Support**: Enterprise authentication per org

## Risk Assessment

1. **Data Migration Risk**: Need careful planning to migrate existing projects without data loss
2. **UX Complexity**: Multi-org adds cognitive overhead for simple use cases
3. **Performance**: Need to ensure org filtering doesn't slow down queries