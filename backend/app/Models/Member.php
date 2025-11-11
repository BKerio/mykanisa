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
        'is_active',
        'email_verified_at',
    ];

    protected $casts = [
        'date_of_birth' => 'date',
        'is_baptized' => 'boolean',
        'takes_holy_communion' => 'boolean',
        'is_active' => 'boolean',
        'email_verified_at' => 'datetime',
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
     */
    public function hasRole($role, $congregation = null, $parish = null, $presbytery = null)
    {
        if (is_string($role)) {
            $role = Role::where('slug', $role)->first();
        }

        if (!$role) {
            return false;
        }

        $query = $this->activeRoles()->where('roles.id', $role->id);

        if ($congregation) {
            $query->wherePivot('congregation', $congregation);
        }
        if ($parish) {
            $query->wherePivot('parish', $parish);
        }
        if ($presbytery) {
            $query->wherePivot('presbytery', $presbytery);
        }

        return $query->exists();
    }

    /**
     * Check if member has any of the given roles
     */
    public function hasAnyRole(array $roles, $congregation = null, $parish = null, $presbytery = null)
    {
        foreach ($roles as $role) {
            if ($this->hasRole($role, $congregation, $parish, $presbytery)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if member has a specific permission
     */
    public function hasPermission($permission)
    {
        return $this->activeRoles()->whereHas('permissions', function($query) use ($permission) {
            if (is_string($permission)) {
                $query->where('slug', $permission);
            } else {
                $query->where('permissions.id', $permission->id);
            }
        })->exists();
    }

    /**
     * Check if member has any of the given permissions
     */
    public function hasAnyPermission(array $permissions)
    {
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
     */
    public function getHighestRoleLevel()
    {
        return $this->activeRoles()->max('hierarchy_level') ?? 0;
    }

    /**
     * Check if member is a leader (has any leadership role)
     */
    public function isLeader($congregation = null, $parish = null, $presbytery = null)
    {
        $leadershipRoles = ['pastor', 'elder', 'deacon', 'chairman', 'secretary', 'treasurer'];
        return $this->hasAnyRole($leadershipRoles, $congregation, $parish, $presbytery);
    }
}
