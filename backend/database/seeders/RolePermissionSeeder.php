<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\Permission;

class RolePermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create permissions
        $permissions = [
            // Member Management
            ['name' => 'View Members', 'slug' => 'view_members', 'description' => 'Can view member information'],
            ['name' => 'Create Members', 'slug' => 'create_members', 'description' => 'Can create new members'],
            ['name' => 'Update Members', 'slug' => 'update_members', 'description' => 'Can update member information'],
            ['name' => 'Delete Members', 'slug' => 'delete_members', 'description' => 'Can delete members'],
            
            // Contribution Management
            ['name' => 'View Contributions', 'slug' => 'view_contributions', 'description' => 'Can view contribution records'],
            ['name' => 'Create Contributions', 'slug' => 'create_contributions', 'description' => 'Can create contribution records'],
            ['name' => 'Update Contributions', 'slug' => 'update_contributions', 'description' => 'Can update contribution records'],
            ['name' => 'Delete Contributions', 'slug' => 'delete_contributions', 'description' => 'Can delete contribution records'],
            
            // Role Management
            ['name' => 'View Roles', 'slug' => 'view_roles', 'description' => 'Can view roles'],
            ['name' => 'Manage Roles', 'slug' => 'manage_roles', 'description' => 'Can create, update, and delete roles'],
            ['name' => 'Assign Roles', 'slug' => 'assign_roles', 'description' => 'Can assign roles to members'],
            ['name' => 'Remove Roles', 'slug' => 'remove_roles', 'description' => 'Can remove roles from members'],
            
            // Permission Management
            ['name' => 'View Permissions', 'slug' => 'view_permissions', 'description' => 'Can view permissions'],
            ['name' => 'Manage Permissions', 'slug' => 'manage_permissions', 'description' => 'Can create, update, and delete permissions'],
            
            // Congregation Management
            ['name' => 'View Congregations', 'slug' => 'view_congregations', 'description' => 'Can view congregation information'],
            ['name' => 'Manage Congregations', 'slug' => 'manage_congregations', 'description' => 'Can manage congregation settings'],
            
            // Reports and Analytics
            ['name' => 'View Reports', 'slug' => 'view_reports', 'description' => 'Can view reports and analytics'],
            ['name' => 'Generate Reports', 'slug' => 'generate_reports', 'description' => 'Can generate custom reports'],
            
            // System Administration
            ['name' => 'System Administration', 'slug' => 'system_admin', 'description' => 'Full system administration access'],
            ['name' => 'User Management', 'slug' => 'manage_users', 'description' => 'Can manage admin users'],
            
            // Financial Management
            ['name' => 'View Financial Records', 'slug' => 'view_financial', 'description' => 'Can view financial records'],
            ['name' => 'Manage Financial Records', 'slug' => 'manage_financial', 'description' => 'Can manage financial records'],
            
            // Communication
            ['name' => 'Send Notifications', 'slug' => 'send_notifications', 'description' => 'Can send notifications to members'],
            ['name' => 'Manage Communications', 'slug' => 'manage_communications', 'description' => 'Can manage church communications'],
        ];

        foreach ($permissions as $permissionData) {
            Permission::firstOrCreate(
                ['slug' => $permissionData['slug']],
                $permissionData
            );
        }

        // Create roles with hierarchy levels (higher number = higher authority)
        $roles = [
            [
                'name' => 'System Administrator',
                'slug' => 'system_admin',
                'description' => 'Full system access with all permissions',
                'is_system_role' => true,
                'hierarchy_level' => 100,
                'permissions' => Permission::pluck('slug')->toArray()
            ],
            [
                'name' => 'General Administrator',
                'slug' => 'admin',
                'description' => 'General administration access',
                'is_system_role' => true,
                'hierarchy_level' => 90,
                'permissions' => [
                    'view_members', 'create_members', 'update_members', 'delete_members',
                    'view_contributions', 'create_contributions', 'update_contributions', 'delete_contributions',
                    'view_roles', 'assign_roles', 'remove_roles',
                    'view_permissions',
                    'view_congregations', 'manage_congregations',
                    'view_reports', 'generate_reports',
                    'view_financial', 'manage_financial',
                    'send_notifications', 'manage_communications'
                ]
            ],
            [
                'name' => 'Pastor',
                'slug' => 'pastor',
                'description' => 'Senior pastoral leadership role',
                'is_system_role' => true,
                'hierarchy_level' => 80,
                'permissions' => [
                    'view_members', 'create_members', 'update_members',
                    'view_contributions', 'create_contributions',
                    'view_roles', 'assign_roles',
                    'view_congregations',
                    'view_reports', 'generate_reports',
                    'view_financial',
                    'send_notifications', 'manage_communications'
                ]
            ],
            [
                'name' => 'Elder',
                'slug' => 'elder',
                'description' => 'Church elder with oversight responsibilities',
                'is_system_role' => true,
                'hierarchy_level' => 80,
                'permissions' => Permission::pluck('slug')->toArray() // Full permissions
            ],
            [
                'name' => 'Deacon',
                'slug' => 'deacon',
                'description' => 'Deacon with service and leadership responsibilities',
                'is_system_role' => true,
                'hierarchy_level' => 60,
                'permissions' => [
                    'view_members', 'create_members',
                    'view_contributions', 'create_contributions',
                    'view_congregations',
                    'view_reports'
                ]
            ],
            [
                'name' => 'Church Chairman',
                'slug' => 'chairman',
                'description' => 'Chairman of the church board',
                'is_system_role' => true,
                'hierarchy_level' => 65,
                'permissions' => [
                    'view_members', 'update_members',
                    'view_contributions', 'create_contributions',
                    'view_congregations',
                    'view_reports', 'generate_reports',
                    'view_financial',
                    'send_notifications'
                ]
            ],
            [
                'name' => 'Church Secretary',
                'slug' => 'secretary',
                'description' => 'Church secretary with administrative duties',
                'is_system_role' => true,
                'hierarchy_level' => 55,
                'permissions' => [
                    'view_members', 'create_members', 'update_members',
                    'view_contributions', 'create_contributions',
                    'view_congregations',
                    'view_reports', 'generate_reports',
                    'send_notifications', 'manage_communications'
                ]
            ],
            [
                'name' => 'Church Treasurer',
                'slug' => 'treasurer',
                'description' => 'Church treasurer with financial oversight',
                'is_system_role' => true,
                'hierarchy_level' => 65,
                'permissions' => [
                    'view_members',
                    'view_contributions', 'create_contributions', 'update_contributions',
                    'view_reports', 'generate_reports',
                    'view_financial', 'manage_financial'
                ]
            ],
            [
                'name' => 'Choir Leader',
                'slug' => 'choir_leader',
                'description' => 'Leader of the church choir',
                'is_system_role' => true,
                'hierarchy_level' => 30,
                'permissions' => [
                    'view_members',
                    'view_contributions',
                    'send_notifications'
                ]
            ],
            [
                'name' => 'Group Leader',
                'slug' => 'group_leader',
                'description' => 'Leader of a church group',
                'is_system_role' => true,
                'hierarchy_level' => 40,
                'permissions' => [
                    'view_members', 'create_members',
                    'view_contributions',
                    'send_notifications'
                ]
            ],
            [
                'name' => 'Women\'s Guild Leader',
                'slug' => 'womens_guild_leader',
                'description' => 'Leader of the women\'s guild',
                'is_system_role' => true,
                'hierarchy_level' => 35,
                'permissions' => [
                    'view_members',
                    'view_contributions',
                    'send_notifications'
                ]
            ],
            [
                'name' => 'Men\'s Fellowship Leader',
                'slug' => 'mens_fellowship_leader',
                'description' => 'Leader of the men\'s fellowship',
                'is_system_role' => true,
                'hierarchy_level' => 35,
                'permissions' => [
                    'view_members',
                    'view_contributions',
                    'send_notifications'
                ]
            ],
            [
                'name' => 'Sunday School Teacher',
                'slug' => 'sunday_school_teacher',
                'description' => 'Sunday school teacher',
                'is_system_role' => true,
                'hierarchy_level' => 25,
                'permissions' => [
                    'view_members',
                    'view_contributions'
                ]
            ],
            [
                'name' => 'Church Member',
                'slug' => 'member',
                'description' => 'Regular church member',
                'is_system_role' => true,
                'hierarchy_level' => 10,
                'permissions' => [
                    'view_members' // Can only view their own profile
                ]
            ]
        ];

        foreach ($roles as $roleData) {
            $permissions = $roleData['permissions'];
            unset($roleData['permissions']);
            
            $role = Role::firstOrCreate(
                ['slug' => $roleData['slug']],
                $roleData
            );
            
            // Attach permissions to role
            $permissionIds = Permission::whereIn('slug', $permissions)->pluck('id');
            $role->permissions()->sync($permissionIds);
        }
    }
}

