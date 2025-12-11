<?php

use App\Models\Member;
use App\Models\Attendance;
use Illuminate\Support\Facades\Http;

// 1. Get a test member
$member = Member::first();

if (!$member) {
    echo "No members found to test with.\n";
    exit(1);
}

echo "Testing with member: {$member->full_name} (ID: {$member->id})\n";

// 2. Simulate API call logic (calling controller method directly or mocking request is hard in script, 
//    easier to just use the code logic or curl if server running. 
//    Let's just use Eloquent to ensure model works first).

try {
    echo "Attempting to create attendance record via Model...\n";
    $attendance = Attendance::create([
        'member_id' => $member->id,
        'e_kanisa_number' => $member->e_kanisa_number,
        'full_name' => $member->full_name,
        'congregation' => $member->congregation,
        'event_type' => 'Test Event',
        'event_date' => now()->toDateString(),
        'scanned_at' => now(),
    ]);

    echo "SUCCESS: Attendance record created. ID: {$attendance->id}\n";
    
    // Clean up
    $attendance->delete();
    echo "Cleaned up test record.\n";

} catch (\Exception $e) {
    echo "ERROR: Failed to create record. " . $e->getMessage() . "\n";
    exit(1);
}
