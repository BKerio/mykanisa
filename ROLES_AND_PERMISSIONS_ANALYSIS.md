# Roles and Permissions System - Comprehensive Analysis

## 📋 Overview

The PCEA Church Management System implements a sophisticated **Role-Based Access Control (RBAC)** system with:
- **17 Permissions** covering various system operations
- **13 System Roles** with hierarchy levels
- **Scope-based role assignments** (congregation/parish/presbytery level)
- **Permission inheritance** through roles
- **Time-bound role assignments** (expiration dates)

---

## 🗄️ Database Schema

### Tables

#### 1. `permissions` Table
```php
- id (primary key)
- name (unique) - e.g., "View Members"
- slug (unique) - e.g., "view_members"
- description (nullable)
- timestamps
```

#### 2. `roles` Table
```php
- id (primary key)
- name - e.g., "Pastor"
- slug (unique) - e.g., "pastor"
- description (nullable)
- is_system_role (boolean) - prevents modification/deletion
- hierarchy_level (integer) - 0-100 (higher = more authority)
- timestamps
```

#### 3. `role_permissions` Pivot Table
```php
- id
- role_id (foreign key → roles)
- permission_id (foreign key → permissions)
- timestamps
- unique(['role_id', 'permission_id'])
```

#### 4. `member_roles` Pivot Table
```php
- id
- member_id (foreign key → members)
- role_id (foreign key → roles)
- congregation (nullable, string 100) - Scope
- parish (nullable, string 100) - Scope
- presbytery (nullable, string 100) - Scope
- assigned_at (timestamp)
- expires_at (nullable, timestamp) - Time-bound assignment
- is_active (boolean) - Soft delete
- timestamps
- index(['member_id', 'role_id', 'congregation', 'parish', 'presbytery'])
- index(['member_id', 'is_active'])
- index(['role_id', 'is_active'])
```

#### 5. `admin_roles` Pivot Table
```php
- id
- admin_id (foreign key → admins)
- role_id (foreign key → roles)
- assigned_at (timestamp)
- expires_at (nullable, timestamp)
- is_active (boolean)
- timestamps
- unique(['admin_id', 'role_id'])
- index(['admin_id', 'is_active'])
```

---

## 🔐 Permissions (17 Total)

### Member Management (4 permissions)
1. **`view_members`** - View member information
2. **`create_members`** - Create new members
3. **`update_members`** - Update member information
4. **`delete_members`** - Delete members

### Contribution Management (4 permissions)
5. **`view_contributions`** - View contribution records
6. **`create_contributions`** - Create contribution records
7. **`update_contributions`** - Update contribution records
8. **`delete_contributions`** - Delete contribution records

### Role Management (4 permissions)
9. **`view_roles`** - View roles
10. **`manage_roles`** - Create, update, and delete roles
11. **`assign_roles`** - Assign roles to members
12. **`remove_roles`** - Remove roles from members

### Permission Management (2 permissions)
13. **`view_permissions`** - View permissions
14. **`manage_permissions`** - Create, update, and delete permissions

### Congregation Management (2 permissions)
15. **`view_congregations`** - View congregation information
16. **`manage_congregations`** - Manage congregation settings

### Reports and Analytics (2 permissions)
17. **`view_reports`** - View reports and analytics
18. **`generate_reports`** - Generate custom reports

### System Administration (2 permissions)
19. **`system_admin`** - Full system administration access
20. **`manage_users`** - Manage admin users

### Financial Management (2 permissions)
21. **`view_financial`** - View financial records
22. **`manage_financial`** - Manage financial records

### Communication (2 permissions)
23. **`send_notifications`** - Send notifications to members
24. **`manage_communications`** - Manage church communications

---

## 👥 System Roles (13 Total)

### Hierarchy Levels (0-100, higher = more authority)

| Role | Slug | Hierarchy | System Role | Description |
|------|------|-----------|-------------|-------------|
| **System Administrator** | `system_admin` | 100 | ✅ | Full system access with ALL permissions |
| **General Administrator** | `admin` | 90 | ✅ | General administration access |
| **Pastor** | `pastor` | 80 | ✅ | Senior pastoral leadership |
| **Elder** | `elder` | 70 | ✅ | Church elder with oversight |
| **Chairman** | `chairman` | 65 | ✅ | Chairman of church board |
| **Treasurer** | `treasurer` | 65 | ✅ | Financial oversight |
| **Deacon** | `deacon` | 60 | ✅ | Service and leadership |
| **Secretary** | `secretary` | 55 | ✅ | Administrative duties |
| **Youth Leader** | `youth_leader` | 40 | ✅ | Youth ministry leader |
| **Women's Guild Leader** | `womens_guild_leader` | 35 | ✅ | Women's guild leader |
| **Men's Fellowship Leader** | `mens_fellowship_leader` | 35 | ✅ | Men's fellowship leader |
| **Choir Leader** | `choir_leader` | 30 | ✅ | Choir leader |
| **Sunday School Teacher** | `sunday_school_teacher` | 25 | ✅ | Sunday school teacher |
| **Church Member** | `member` | 10 | ✅ | Regular church member |

---

## 🎯 Role Permissions Matrix

### System Administrator (Level 100)
**Permissions:** ALL permissions (20+)

### General Administrator (Level 90)
**Permissions:**
- ✅ Member: `view`, `create`, `update`, `delete`
- ✅ Contributions: `view`, `create`, `update`, `delete`
- ✅ Roles: `view`, `assign`, `remove`
- ✅ Permissions: `view`
- ✅ Congregations: `view`, `manage`
- ✅ Reports: `view`, `generate`
- ✅ Financial: `view`, `manage`
- ✅ Communication: `send_notifications`, `manage_communications`
- ❌ Role Management: Cannot `manage_roles` (create/delete)
- ❌ Permission Management: Cannot `manage_permissions`
- ❌ System Admin: No `system_admin` permission
- ❌ User Management: No `manage_users` permission

### Pastor (Level 80)
**Permissions:**
- ✅ Member: `view`, `create`, `update`
- ✅ Contributions: `view`, `create`
- ✅ Roles: `view`, `assign`
- ✅ Congregations: `view`
- ✅ Reports: `view`, `generate`
- ✅ Financial: `view`
- ✅ Communication: `send_notifications`, `manage_communications`
- ❌ Member: Cannot `delete`
- ❌ Contributions: Cannot `update`, `delete`
- ❌ Roles: Cannot `manage`, `remove`

### Elder (Level 70)
**Permissions:**
- ✅ Member: `view`, `create`, `update`
- ✅ Contributions: `view`, `create`
- ✅ Roles: `view`, `assign`
- ✅ Congregations: `view`
- ✅ Reports: `view`
- ✅ Financial: `view`
- ✅ Communication: `send_notifications`
- ❌ Member: Cannot `delete`
- ❌ Contributions: Cannot `update`, `delete`
- ❌ Reports: Cannot `generate`
- ❌ Communication: Cannot `manage_communications`

### Chairman (Level 65)
**Permissions:**
- ✅ Member: `view`, `update`
- ✅ Contributions: `view`, `create`
- ✅ Congregations: `view`
- ✅ Reports: `view`, `generate`
- ✅ Financial: `view`
- ✅ Communication: `send_notifications`
- ❌ Member: Cannot `create`, `delete`
- ❌ Roles: No role management permissions

### Treasurer (Level 65)
**Permissions:**
- ✅ Member: `view`
- ✅ Contributions: `view`, `create`, `update`
- ✅ Reports: `view`, `generate`
- ✅ Financial: `view`, `manage`
- ❌ Member: Cannot `create`, `update`, `delete`
- ❌ Communication: No communication permissions

### Deacon (Level 60)
**Permissions:**
- ✅ Member: `view`, `create`
- ✅ Contributions: `view`, `create`
- ✅ Congregations: `view`
- ✅ Reports: `view`
- ❌ Member: Cannot `update`, `delete`
- ❌ Contributions: Cannot `update`, `delete`
- ❌ Roles: No role management
- ❌ Financial: No financial access

### Secretary (Level 55)
**Permissions:**
- ✅ Member: `view`, `create`, `update`
- ✅ Contributions: `view`, `create`
- ✅ Congregations: `view`
- ✅ Reports: `view`, `generate`
- ✅ Communication: `send_notifications`, `manage_communications`
- ❌ Member: Cannot `delete`
- ❌ Contributions: Cannot `update`, `delete`

### Youth Leader (Level 40)
**Permissions:**
- ✅ Member: `view`, `create`
- ✅ Contributions: `view`
- ✅ Communication: `send_notifications`
- ❌ Limited to youth ministry scope

### Choir Leader (Level 30)
**Permissions:**
- ✅ Member: `view`
- ✅ Contributions: `view`
- ✅ Communication: `send_notifications`
- ❌ Limited to choir scope

### Sunday School Teacher (Level 25)
**Permissions:**
- ✅ Member: `view`
- ✅ Contributions: `view`
- ❌ Limited to Sunday school scope

### Church Member (Level 10)
**Permissions:**
- ✅ Member: `view` (own profile only)
- ❌ All other permissions denied

---

## 🔧 Implementation Details

### Model Methods

#### Member Model
```php
// Role checks
hasRole($role, $congregation = null, $parish = null, $presbytery = null)
hasAnyRole(array $roles, $congregation = null, $parish = null, $presbytery = null)
rolesForScope($congregation = null, $parish = null, $presbytery = null)
activeRoles() // Filters by is_active and expiration

// Permission checks
hasPermission($permission)
hasAnyPermission(array $permissions)

// Role management
assignRole($role, $congregation = null, $parish = null, $presbytery = null, $expiresAt = null)
removeRole($role, $congregation = null, $parish = null, $presbytery = null)

// Utility methods
isLeader($congregation = null, $parish = null, $presbytery = null)
getHighestRoleLevel()
```

#### Admin Model
```php
// Role checks (no scope)
hasRole($role)
hasAnyRole(array $roles)
activeRoles()

// Permission checks
hasPermission($permission)
hasAnyPermission(array $permissions)

// Role management
assignRole($role, $expiresAt = null)
removeRole($role)
```

#### Role Model
```php
// Permission management
hasPermission($permission)
givePermission($permission)
revokePermission($permission)
syncPermissions(array $permissions)

// Utility methods
findBySlug($slug)
scopeSystemRoles()
scopeCustomRoles()
```

---

## 🛡️ Middleware

### 1. `EnsureRole` Middleware
**Usage:** `middleware('role:pastor,elder')`
- Checks if user has ANY of the specified roles
- Supports scope for members (congregation/parish/presbytery)
- Admins bypass role checks

### 2. `RoleMiddleware` Middleware
**Usage:** `middleware('role:pastor')`
- Checks if user has the specific role
- Supports scope via request parameters or headers
- Works with Members, Admins, and Users

### 3. `EnsurePermission` Middleware
**Usage:** `middleware('permission:view_members,manage_members')`
- Checks if user has ANY of the specified permissions
- Works through role inheritance

### 4. `PermissionMiddleware` Middleware
**Usage:** `middleware('permission:view_members')`
- Checks if user has the specific permission
- Works with Members and Admins

### 5. `EnsureLeadership` Middleware
**Usage:** `middleware('leadership')`
- Checks if user is a leader (pastor, elder, deacon, chairman)
- Admins are always considered leaders
- Supports scope for members

---

## 🌐 API Routes

### Role Management (Admin Only)
```
GET    /api/admin/roles                      - List all roles
POST   /api/admin/roles                      - Create role
GET    /api/admin/roles/{role}               - Show role
PUT    /api/admin/roles/{role}               - Update role
DELETE /api/admin/roles/{role}               - Delete role
POST   /api/admin/roles/{role}/assign-member - Assign role to member
DELETE /api/admin/roles/{role}/remove-member - Remove role from member
GET    /api/admin/roles/{role}/members       - Get members with role
GET    /api/admin/roles/{role}/permissions   - Get role permissions
```

### Permission Management (Admin Only)
```
GET    /api/admin/permissions                - List all permissions
POST   /api/admin/permissions                - Create permission
GET    /api/admin/permissions/{permission}   - Show permission
PUT    /api/admin/permissions/{permission}   - Update permission
DELETE /api/admin/permissions/{permission}   - Delete permission
```

### Leadership Dashboard
```
GET    /api/leadership/dashboard             - Get user's roles and permissions
```

---

## 📱 Mobile App (Flutter)

### Dashboard Factory
The mobile app uses a `DashboardFactory` to route users to role-specific dashboards:

```dart
DashboardFactory.createDashboard(String role)
```

**Supported Roles:**
- `pastor` → PastorDashboard
- `elder` → ElderDashboard
- `deacon` → DeaconDashboard
- `secretary` → SecretaryDashboard
- `treasurer` → TreasurerDashboard
- `choir_leader` → ChoirLeaderDashboard
- `youth_leader` → YouthLeaderDashboard
- `sunday_school_teacher` → SundaySchoolTeacherDashboard
- `member` → MemberDashboard (default)

### Role-Based UI
- Each role has a dedicated dashboard screen
- Dashboard cards are role-specific
- Color schemes per role
- Icons per role

---

## 🔍 Key Features

### 1. **Scope-Based Access Control**
- Roles can be assigned at **congregation**, **parish**, or **presbytery** level
- Same member can have different roles at different scopes
- Example: Member can be Elder at Congregation A but Member at Congregation B

### 2. **Time-Bound Roles**
- Roles can have expiration dates (`expires_at`)
- Expired roles are automatically filtered out
- Useful for temporary assignments (e.g., acting pastor)

### 3. **System Role Protection**
- System roles (`is_system_role = true`) cannot be:
  - Modified
  - Deleted
- Custom roles can be fully managed

### 4. **Hierarchy System**
- Hierarchy levels (0-100) determine authority
- Higher levels = more authority
- Used for:
  - Role comparison
  - Display ordering
  - Access control logic

### 5. **Soft Delete**
- Roles are soft-deleted (`is_active = false`)
- Prevents data loss
- Allows reactivation

### 6. **Permission Inheritance**
- Permissions are granted through roles
- Users get permissions from all their active roles
- No direct permission assignment to users

---

## ⚠️ Issues & Recommendations

### Current Issues

1. **Duplicate Middleware**
   - Both `EnsureRole` and `RoleMiddleware` exist with similar functionality
   - **Recommendation:** Consolidate into one middleware

2. **Inconsistent Role Checking**
   - Some routes use `role:pastor`, others use `EnsureRole` middleware
   - **Recommendation:** Standardize middleware usage

3. **Missing Permission Checks in Some Routes**
   - Some routes check roles but not specific permissions
   - **Recommendation:** Add granular permission checks

4. **No Role Assignment Validation**
   - No check if assigner has permission to assign the role
   - **Recommendation:** Add validation in `assignRole` methods

5. **User Model Missing Role/Permission Methods**
   - User model doesn't implement role/permission checks
   - Uses workaround to find associated Member
   - **Recommendation:** Add methods to User model or standardize authentication

### Recommendations

1. **Add Permission-Based Route Protection**
   ```php
   Route::middleware(['auth:sanctum', 'permission:manage_members'])
       ->group(function() {
           // Routes
       });
   ```

2. **Implement Role Hierarchy Checks**
   - Prevent users from assigning roles higher than their own
   - Example: Elder cannot assign Pastor role

3. **Add Audit Logging**
   - Log all role assignments/removals
   - Track who assigned roles and when

4. **Add Role Assignment Workflows**
   - Require approval for sensitive role assignments
   - Notify relevant parties on role changes

5. **Improve Error Messages**
   - Provide specific feedback when permission denied
   - Include required permission/role in error message

6. **Add Bulk Role Assignment**
   - Allow assigning roles to multiple members at once
   - Useful for group promotions

7. **Permission Groups**
   - Group related permissions (e.g., "Member Management" group)
   - Easier to manage and assign

8. **Role Templates**
   - Pre-defined permission sets for common roles
   - Faster role creation

---

## ✅ Best Practices Implemented

1. ✅ **Separation of Concerns** - Clear model/middleware separation
2. ✅ **Scope Support** - Multi-level scope (congregation/parish/presbytery)
3. ✅ **Soft Deletes** - `is_active` flag for soft deletes
4. ✅ **Expiration Support** - Time-bound role assignments
5. ✅ **System Role Protection** - Prevents modification of system roles
6. ✅ **Hierarchy System** - Numeric hierarchy levels
7. ✅ **Permission Inheritance** - Through roles
8. ✅ **Flexible Assignment** - String or object role/permission input

---

## 📊 Statistics

- **Total Permissions:** 20+
- **Total System Roles:** 13
- **Middleware Classes:** 5
- **Model Methods:** 20+
- **API Endpoints:** 15+ for roles/permissions
- **Database Tables:** 5 (permissions, roles, role_permissions, member_roles, admin_roles)

---

## 🔗 Related Files

### Backend
- `backend/app/Models/Role.php`
- `backend/app/Models/Permission.php`
- `backend/app/Models/Member.php`
- `backend/app/Models/Admin.php`
- `backend/app/Http/Controllers/Admin/RolesController.php`
- `backend/app/Http/Controllers/Admin/PermissionsController.php`
- `backend/app/Http/Middleware/*.php`
- `backend/database/migrations/2025_01_15_000001_create_roles_and_permissions_tables.php`
- `backend/database/seeders/RolePermissionSeeder.php`

### Mobile App
- `pcea_church/lib/screen/dashboard_factory.dart`
- `pcea_church/lib/screen/base_dashboard.dart`

### Admin Panel
- `adminpanel/src/pages/roles.tsx` (if exists)

---

## 📝 Summary

The roles and permissions system is **well-structured and comprehensive**, providing:
- ✅ Flexible scope-based access control
- ✅ Hierarchical role system
- ✅ Permission-based authorization
- ✅ Time-bound role assignments
- ✅ Protection for system roles

**Areas for improvement:**
- Consolidate duplicate middleware
- Add more granular permission checks
- Implement role hierarchy validation
- Add audit logging
- Improve error messaging

**Overall Grade: A-**

The system is production-ready but could benefit from the recommended improvements for enhanced security and usability.

