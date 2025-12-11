<?php

require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\AuditLog;
use App\Models\User;
use App\Models\Member;

// Check first 5 logs
echo "--- Audit Logs Check ---\n";
$logs = AuditLog::with('user')->orderBy('created_at', 'desc')->take(5)->get();
foreach ($logs as $log) {
    echo "ID: {$log->id}, UserID: {$log->user_id}, Type: {$log->user_type}, User Loaded: " . ($log->user ? 'Yes' : 'No') . "\n";
    if ($log->user) {
        echo " - User Class: " . get_class($log->user) . "\n";
        echo " - User Email: " . $log->user->email . "\n";
        if (method_exists($log->user, 'member')) {
            $member = $log->user->member;
            echo " - Member Loaded: " . ($member ? 'Yes (' . $member->full_name . ')' : 'No') . "\n";
        }
    }
}

// Check User-Member Relation
echo "\n--- User-Member Relation Check ---\n";
$user = User::first();
if ($user) {
    echo "User: {$user->email}\n";
    $member = Member::where('email', $user->email)->first();
    echo "Member by Email query: " . ($member ? "Found ({$member->full_name})" : "Not Found") . "\n";
    echo "User->member relation: " . ($user->member ? "Found ({$user->member->full_name})" : "Not Found") . "\n";
} else {
    echo "No users found.\n";
}
