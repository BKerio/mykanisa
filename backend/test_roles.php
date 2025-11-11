<?php

require_once 'vendor/autoload.php';

use App\Models\Role;
use App\Models\Permission;
use App\Models\Member;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Testing Roles and Permissions System ===\n\n";

// 1. Check if roles exist
echo "1. Checking roles...\n";
$chairmanRole = Role::where('slug', 'chairman')->first();
$sundaySchoolTeacherRole = Role::where('slug', 'sunday_school_teacher')->first();

if ($chairmanRole) {
    echo "✓ Chairman role exists (ID: {$chairmanRole->id})\n";
    echo "  - Name: {$chairmanRole->name}\n";
    echo "  - Hierarchy Level: {$chairmanRole->hierarchy_level}\n";
    echo "  - Permissions: " . $chairmanRole->permissions()->count() . "\n";
} else {
    echo "✗ Chairman role not found\n";
}

if ($sundaySchoolTeacherRole) {
    echo "✓ Sunday School Teacher role exists (ID: {$sundaySchoolTeacherRole->id})\n";
    echo "  - Name: {$sundaySchoolTeacherRole->name}\n";
    echo "  - Hierarchy Level: {$sundaySchoolTeacherRole->hierarchy_level}\n";
    echo "  - Permissions: " . $sundaySchoolTeacherRole->permissions()->count() . "\n";
} else {
    echo "✗ Sunday School Teacher role not found\n";
}

echo "\n";

// 2. Check permissions
echo "2. Checking permissions...\n";
$permissions = Permission::whereIn('slug', [
    'manage_sunday_school',
    'view_sunday_school_members',
    'create_sunday_school_events',
    'manage_sunday_school_curriculum',
    'view_leadership_dashboard',
    'assign_roles'
])->get();

foreach ($permissions as $permission) {
    echo "✓ {$permission->name} ({$permission->slug})\n";
}

echo "\n";

// 3. Test role assignment (if members exist)
echo "3. Testing role assignment...\n";
$testMember = Member::first();
if ($testMember) {
    echo "Testing with member: {$testMember->full_name} ({$testMember->email})\n";
    
    // Assign chairman role
    $result = $testMember->assignRole('chairman', 'Test Congregation', 'Test Parish', 'Test Presbytery');
    if ($result) {
        echo "✓ Successfully assigned chairman role\n";
        
        // Test role check
        $hasRole = $testMember->hasRole('chairman', 'Test Congregation', 'Test Parish', 'Test Presbytery');
        echo "✓ Role check: " . ($hasRole ? 'PASS' : 'FAIL') . "\n";
        
        // Test permission check
        $hasPermission = $testMember->hasPermission('view_leadership_dashboard');
        echo "✓ Permission check (view_leadership_dashboard): " . ($hasPermission ? 'PASS' : 'FAIL') . "\n";
        
        // Remove role for clean test
        $testMember->removeRole('chairman', 'Test Congregation', 'Test Parish', 'Test Presbytery');
        echo "✓ Cleaned up test role assignment\n";
    } else {
        echo "✗ Failed to assign chairman role\n";
    }
} else {
    echo "No members found to test with\n";
}

echo "\n";

// 4. Test Sunday School Teacher role
if ($testMember) {
    echo "4. Testing Sunday School Teacher role...\n";
    
    $result = $testMember->assignRole('sunday_school_teacher', 'Test Congregation');
    if ($result) {
        echo "✓ Successfully assigned Sunday School Teacher role\n";
        
        // Test role check
        $hasRole = $testMember->hasRole('sunday_school_teacher', 'Test Congregation');
        echo "✓ Role check: " . ($hasRole ? 'PASS' : 'FAIL') . "\n";
        
        // Test permission check
        $hasPermission = $testMember->hasPermission('manage_sunday_school');
        echo "✓ Permission check (manage_sunday_school): " . ($hasPermission ? 'PASS' : 'FAIL') . "\n";
        
        // Remove role for clean test
        $testMember->removeRole('sunday_school_teacher', 'Test Congregation');
        echo "✓ Cleaned up test role assignment\n";
    } else {
        echo "✗ Failed to assign Sunday School Teacher role\n";
    }
}

echo "\n";

// 5. Show all available roles
echo "5. All available roles:\n";
$allRoles = Role::orderBy('hierarchy_level', 'desc')->get();
foreach ($allRoles as $role) {
    echo "  - {$role->name} ({$role->slug}) - Level {$role->hierarchy_level}\n";
}

echo "\n=== Test Complete ===\n";




