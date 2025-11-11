<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class Admin extends Authenticatable
{
    use HasFactory, HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get all roles for this admin
     */
    public function roles()
    {
        return $this->belongsToMany(Role::class, 'admin_roles')
            ->withPivot(['assigned_at', 'expires_at', 'is_active'])
            ->withTimestamps();
    }

    /**
     * Get active roles for this admin
     */
    public function activeRoles()
    {
        return $this->roles()->wherePivot('is_active', true)
            ->where(function($query) {
                $query->whereNull('admin_roles.expires_at')
                      ->orWhere('admin_roles.expires_at', '>', now());
            });
    }

    /**
     * Check if admin has a specific role
     */
    public function hasRole($role)
    {
        if (is_string($role)) {
            $role = Role::where('slug', $role)->first();
        }

        if (!$role) {
            return false;
        }

        return $this->activeRoles()->where('roles.id', $role->id)->exists();
    }

    /**
     * Check if admin has any of the given roles
     */
    public function hasAnyRole(array $roles)
    {
        foreach ($roles as $role) {
            if ($this->hasRole($role)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Check if admin has a specific permission
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
     * Check if admin has any of the given permissions
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
     * Assign role to admin
     */
    public function assignRole($role, $expiresAt = null)
    {
        if (is_string($role)) {
            $role = Role::where('slug', $role)->first();
        }

        if (!$role) {
            return false;
        }

        // Check if role is already assigned
        $existingRole = $this->roles()->where('roles.id', $role->id)->first();

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
                'assigned_at' => now(),
                'expires_at' => $expiresAt,
                'is_active' => true,
            ]);
        }

        return true;
    }

    /**
     * Remove role from admin
     */
    public function removeRole($role)
    {
        if (is_string($role)) {
            $role = Role::where('slug', $role)->first();
        }

        if (!$role) {
            return false;
        }

        $this->roles()->updateExistingPivot($role->id, [
            'is_active' => false,
            'updated_at' => now(),
        ]);

        return true;
    }
}
