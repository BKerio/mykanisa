<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Create permissions table
        Schema::create('permissions', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        // Create roles table
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->boolean('is_system_role')->default(false);
            $table->integer('hierarchy_level')->default(0);
            $table->timestamps();
        });

        // Create role_permissions pivot table
        Schema::create('role_permissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('role_id')->constrained()->cascadeOnDelete();
            $table->foreignId('permission_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['role_id', 'permission_id']);
        });

        // Create member_roles pivot table (depends on members)
        if (Schema::hasTable('members')) {
            Schema::create('member_roles', function (Blueprint $table) {
                $table->id();
                $table->foreignId('member_id')->constrained('members')->cascadeOnDelete();
                $table->foreignId('role_id')->constrained()->cascadeOnDelete();
                $table->string('congregation', 100)->nullable();
                $table->string('parish', 100)->nullable();
                $table->string('presbytery', 100)->nullable();
                $table->timestamp('assigned_at')->useCurrent();
                $table->timestamp('expires_at')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
                // Use a composite index instead of unique to avoid engine rename issues
                $table->index(['member_id', 'role_id', 'congregation', 'parish', 'presbytery'], 'member_roles_scope_index');
                $table->index(['member_id', 'is_active']);
                $table->index(['role_id', 'is_active']);
            });
        }

        // Create admin_roles pivot table (depends on admins)
        if (Schema::hasTable('admins')) {
            Schema::create('admin_roles', function (Blueprint $table) {
                $table->id();
                $table->foreignId('admin_id')->constrained('admins')->cascadeOnDelete();
                $table->foreignId('role_id')->constrained()->cascadeOnDelete();
                $table->timestamp('assigned_at')->useCurrent();
                $table->timestamp('expires_at')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
                $table->unique(['admin_id', 'role_id']);
                $table->index(['admin_id', 'is_active']);
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('admin_roles');
        Schema::dropIfExists('member_roles');
        Schema::dropIfExists('role_permissions');
        Schema::dropIfExists('roles');
        Schema::dropIfExists('permissions');
    }
};


