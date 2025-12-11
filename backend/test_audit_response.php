<?php

require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\AuditLog;
use Illuminate\Database\Eloquent\Relations\MorphTo;

// Simulate the Controller Logic
$logs = AuditLog::with(['user' => function (MorphTo $morphTo) {
    $morphTo->morphWith([
        \App\Models\User::class => ['member'],
    ]);
}])->orderBy('created_at', 'desc')->take(5)->get();

echo "--- JSON Response Preview ---\n";
foreach ($logs as $log) {
    echo "ID: " . $log->id . "\n";
    echo "User Type: " . $log->user_type . "\n";
    echo "User ID: " . $log->user_id . "\n";
    
    if ($log->user) {
        echo "User Class: " . get_class($log->user) . "\n";
        echo "User Name: " . $log->user->name . "\n";
        if ($log->user instanceof \App\Models\User) {
            echo "Member Loaded: " . ($log->user->relationLoaded('member') ? 'Yes' : 'No') . "\n";
            echo "Member Name: " . ($log->user->member ? $log->user->member->full_name : 'NULL') . "\n";
        }
    } else {
        echo "User: NULL\n";
    }
    echo "------------------------\n";
}
