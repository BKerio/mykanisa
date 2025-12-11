<?php

require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use App\Services\AuditService;

echo "--- Backfill Start ---\n";

// Fix legacy logs (assume User model for now if empty)
$count = DB::table('audit_logs')
    ->whereNotNull('user_id')
    ->where(function($q) {
        $q->whereNull('user_type')->orWhere('user_type', '');
    })
    ->update(['user_type' => 'App\Models\User']);

echo "Updated $count existing logs to 'App\Models\User'.\n";

// Create a TEST log to verify AuditService works correctly now
echo "\n--- Creating Verification Log ---\n";
$firstUser = User::first();
if ($firstUser) {
    AuditService::log('Test', 'System verification log', null, null, $firstUser);
    echo "Created verification log for User ID: " . $firstUser->id . "\n";
    
    // Fetch it back
    $log = AuditLog::orderBy('created_at', 'desc')->first();
    echo "Latest Log ID: " . $log->id . "\n";
    echo "Latest Log User Type: '" . $log->user_type . "'\n";
    
    if ($log->user_type === 'App\Models\User' || $log->user_type === trim('App\Models\User', '\\')) {
         echo "SUCCESS: User Type is correctly populated.\n";
    } else {
         echo "FAILURE: User Type is still empty or incorrect.\n";
    }
} else {
    echo "No users found to test logging.\n";
}
