<?php

namespace App\Console\Commands;

use App\Models\Role;
use App\Models\Permission;
use Illuminate\Console\Command;

class UpdateElderPermissions extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'elder:give-full-permissions';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Update Elder role to have all permissions';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Updating Elder role permissions...');

        $elderRole = Role::where('slug', 'elder')->first();

        if (!$elderRole) {
            $this->error('Elder role not found!');
            return Command::FAILURE;
        }

        // Get all permissions
        $allPermissions = Permission::pluck('id')->toArray();

        // Sync all permissions to Elder role
        $elderRole->permissions()->sync($allPermissions);

        // Update hierarchy level to 80 (same as Pastor)
        $elderRole->update(['hierarchy_level' => 80]);

        $permissionCount = Permission::count();
        $this->info("✓ Elder role updated successfully!");
        $this->info("✓ Assigned {$permissionCount} permissions");
        $this->info("✓ Hierarchy level set to 80");

        return Command::SUCCESS;
    }
}

