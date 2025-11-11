<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'description',
        'is_system_role',
        'hierarchy_level',
    ];

    protected $casts = [
        'is_system_role' => 'boolean',
        'hierarchy_level' => 'integer',
    ];

    /**
     * Get all permissions for this role
     */
    public function permissions()
    {
        return $this->belongsToMany(Permission::class, 'role_permissions');
    }

    /**
     * Get all members with this role
     */
    public function members()
    {
        return $this->belongsToMany(Member::class, 'member_roles')
            ->withPivot(['congregation', 'parish', 'presbytery', 'assigned_at', 'expires_at', 'is_active'])
            ->withTimestamps();
    }

    /**
     * Get all admins with this role
     */
    public function admins()
    {
        return $this->belongsToMany(Admin::class, 'admin_roles')
            ->withPivot(['assigned_at', 'expires_at', 'is_active'])
            ->withTimestamps();
    }

    /**
     * Check if role has a specific permission
     */
    public function hasPermission($permission)
    {
        if (is_string($permission)) {
            return $this->permissions()->where('slug', $permission)->exists();
        }
        
        if ($permission instanceof Permission) {
            return $this->permissions()->where('permission_id', $permission->id)->exists();
        }

        return false;
    }

    /**
     * Give permission to role
     */
    public function givePermission($permission)
    {
        if (is_string($permission)) {
            $permission = Permission::where('slug', $permission)->first();
        }

        if ($permission && !$this->hasPermission($permission)) {
            $this->permissions()->attach($permission->id);
        }

        return $this;
    }

    /**
     * Remove permission from role
     */
    public function revokePermission($permission)
    {
        if (is_string($permission)) {
            $permission = Permission::where('slug', $permission)->first();
        }

        if ($permission) {
            $this->permissions()->detach($permission->id);
        }

        return $this;
    }

    /**
     * Sync permissions for role
     */
    public function syncPermissions(array $permissions)
    {
        $permissionIds = [];
        
        foreach ($permissions as $permission) {
            if (is_string($permission)) {
                $permission = Permission::where('slug', $permission)->first();
            }
            
            if ($permission) {
                $permissionIds[] = $permission->id;
            }
        }

        $this->permissions()->sync($permissionIds);
        
        return $this;
    }

    /**
     * Check if role exists by slug
     */
    public static function findBySlug($slug)
    {
        return static::where('slug', $slug)->first();
    }

    /**
     * Scope for system roles
     */
    public function scopeSystemRoles($query)
    {
        return $query->where('is_system_role', true);
    }

    /**
     * Scope for custom roles
     */
    public function scopeCustomRoles($query)
    {
        return $query->where('is_system_role', false);
    }
}

