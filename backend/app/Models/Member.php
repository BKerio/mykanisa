<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Member extends Model
{
    use HasFactory;

    protected $fillable = [
        'full_name',
        'date_of_birth',
        'age',
        'national_id',
        'email',
        'profile_image',
        'passport_image',
        'gender',
        'marital_status',
        'primary_school',
        'is_baptized',
        'takes_holy_communion',
        'presbytery',
        'parish',
        'district',
        'congregation',
        'groups',
        'e_kanisa_number',
        'telephone',
        'region',
        'role',
        'assigned_group_ids',
        'is_active',
        'email_verified_at',
    ];

    protected $casts = [
        'date_of_birth' => 'date',
        'is_baptized' => 'boolean',
        'takes_holy_communion' => 'boolean',
        'is_active' => 'boolean',
        'email_verified_at' => 'datetime',
        'assigned_group_ids' => 'array',
    ];

    public function dependencies()
    {
        return $this->hasMany(Dependency::class);
    }

    public function contributions()
    {
        return $this->hasMany(Contribution::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function groups()
    {
        return $this->belongsToMany(Group::class, 'group_member')->withTimestamps();
    }

    /**
     * Get the assigned groups for group leaders
     * Returns a collection of Groups based on the JSON IDs
     */
    public function assignedGroups()
    {
        // Since we can't use a direct relationship for JSON array, 
        // we'll return a query builder constrained by the IDs
        $ids = $this->assigned_group_ids ?? [];
        if (!is_array($ids)) {
            // Handle migrated data case or string format
            $ids = json_decode($ids, true) ?? [];
            if (!is_array($ids) && !empty($this->assigned_group_ids)) {
                $ids = [(int)$this->assigned_group_ids];
            }
        }
        
        return Group::whereIn('id', $ids);
    }

    /**
     * Helper to get assigned groups as a collection immediately
     */
    public function getAssignedGroupsAttribute()
    {
        return $this->assignedGroups()->get();
    }

    /**
     * Check if member is part of a specific group
     */
    public function isMemberOfGroup($groupId)
    {
        // Check in the JSON groups field
        if ($this->groups) {
            try {
                $groupIds = is_string($this->groups) ? json_decode($this->groups, true) : $this->groups;
                if (is_array($groupIds) && in_array((int)$groupId, array_map('intval', $groupIds))) {
                    return true;
                }
            } catch (\Exception $e) {
                // Invalid JSON, continue to check pivot table
            }
        }
        
        // Also check the pivot table relationship
        return $this->groups()->where('groups.id', $groupId)->exists();
    }

    /**
     * Get all roles for this member
     */
    public function roles()
    {
        return $this->belongsToMany(Role::class, 'member_roles')
            ->withPivot(['congregation', 'parish', 'presbytery', 'assigned_at', 'expires_at', 'is_active'])
            ->withTimestamps();
    }

    /**
     * Get active roles for this member
     */
    public function activeRoles()
    {
        return $this->roles()->wherePivot('is_active', true)
            ->where(function($query) {
                $query->whereNull('member_roles.expires_at')
                      ->orWhere('member_roles.expires_at', '>', now());
            });
    }

    /**
     * Get roles for specific congregation/parish/presbytery
     */
    public function rolesForScope($congregation = null, $parish = null, $presbytery = null)
    {
        $query = $this->activeRoles();

        if ($congregation) {
            $query->wherePivot('congregation', $congregation);
        }
        if ($parish) {
            $query->wherePivot('parish', $parish);
        }
        if ($presbytery) {
            $query->wherePivot('presbytery', $presbytery);
        }

        return $query;
    }

    /**
     * Check if member has a specific role
     * Uses the 'role' field in members table instead of member_roles relationship
     */
    public function hasRole($role, $congregation = null, $parish = null, $presbytery = null)
    {
        // Elder has full permissions - always return true if checking for any role
        // Check if member has elder role in the role field first
        $memberRole = strtolower(trim($this->role ?? 'member'));
        
        if ($memberRole === 'elder') {
            return true;
        }
        
        // Normalize role comparison
        if (is_string($role)) {
            $roleSlug = strtolower(trim($role));
        } elseif (is_object($role) && isset($role->slug)) {
            $roleSlug = strtolower(trim($role->slug));
        } else {
            return false;
        }

        // Check if member's role matches (case-insensitive)
        return $memberRole === $roleSlug;
    }

    /**
     * Check if member has any of the given roles
     * Uses the 'role' field in members table instead of member_roles relationship
     */
    public function hasAnyRole(array $roles, $congregation = null, $parish = null, $presbytery = null)
    {
        // Elder has full permissions - always return true
        $memberRole = strtolower(trim($this->role ?? 'member'));
        if ($memberRole === 'elder') {
            return true;
        }
        
        // Normalize member role and check against provided roles
        foreach ($roles as $role) {
            if (is_string($role)) {
                $roleSlug = strtolower(trim($role));
            } elseif (is_object($role) && isset($role->slug)) {
                $roleSlug = strtolower(trim($role->slug));
            } else {
                continue;
            }
            
            if ($memberRole === $roleSlug) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if member has a specific permission
     * Elder has full permissions - always returns true for elder role
     */
    public function hasPermission($permission)
    {
        // Elder has full permissions - always return true
        $memberRole = strtolower(trim($this->role ?? 'member'));
        if ($memberRole === 'elder') {
            return true;
        }
        
        // For other roles, check permissions through role_permissions table
        // First get the member's role from members.role field
        $role = Role::where('slug', $memberRole)->first();
        if (!$role) {
            return false;
        }
        
        // Check if role has the permission
        if (is_string($permission)) {
            return $role->permissions()->where('slug', $permission)->exists();
        } else {
            return $role->permissions()->where('permissions.id', $permission->id)->exists();
        }
    }

    /**
     * Check if member has any of the given permissions
     */
    public function hasAnyPermission(array $permissions)
    {
        // Elder has full permissions - always return true
        if ($this->hasRole('elder')) {
            return true;
        }
        
        foreach ($permissions as $permission) {
            if ($this->hasPermission($permission)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Assign role to member
     */
    public function assignRole($role, $congregation = null, $parish = null, $presbytery = null, $expiresAt = null)
    {
        if (is_string($role)) {
            $role = Role::where('slug', $role)->first();
        }

        if (!$role) {
            return false;
        }

        // Check if role is already assigned
        $existingRole = $this->roles()->where('roles.id', $role->id)
            ->wherePivot('congregation', $congregation)
            ->wherePivot('parish', $parish)
            ->wherePivot('presbytery', $presbytery)
            ->first();

        if ($existingRole) {
            // Update existing role assignment
            $this->roles()->updateExistingPivot($role->id, [
                'is_active' => true,
                'expires_at' => $expiresAt,
                'updated_at' => now(),
            ]);
        } else {
            // Create new role assignment
            $this->roles()->attach($role->id, [
                'congregation' => $congregation,
                'parish' => $parish,
                'presbytery' => $presbytery,
                'assigned_at' => now(),
                'expires_at' => $expiresAt,
                'is_active' => true,
            ]);
        }

        return true;
    }

    /**
     * Remove role from member
     */
    public function removeRole($role, $congregation = null, $parish = null, $presbytery = null)
    {
        if (is_string($role)) {
            $role = Role::where('slug', $role)->first();
        }

        if (!$role) {
            return false;
        }

        $query = $this->roles()->where('roles.id', $role->id);

        if ($congregation) {
            $query->wherePivot('congregation', $congregation);
        }
        if ($parish) {
            $query->wherePivot('parish', $parish);
        }
        if ($presbytery) {
            $query->wherePivot('presbytery', $presbytery);
        }

        $query->updateExistingPivot($role->id, [
            'is_active' => false,
            'updated_at' => now(),
        ]);

        return true;
    }

    /**
     * Get the highest hierarchy level role for this member
     * Uses the 'role' field in members table instead of member_roles relationship
     */
    public function getHighestRoleLevel()
    {
        $memberRole = strtolower(trim($this->role ?? 'member'));
        $role = Role::where('slug', $memberRole)->first();
        return $role ? $role->hierarchy_level : 0;
    }

    /**
     * Check if member is a leader (has any leadership role)
     * Uses the 'role' field in members table instead of member_roles relationship
     */
    public function isLeader($congregation = null, $parish = null, $presbytery = null)
    {
        $leadershipRoles = ['pastor', 'elder', 'deacon', 'chairman', 'secretary', 'treasurer'];
        return $this->hasAnyRole($leadershipRoles);
    }
}
