<?php

require_once 'vendor/autoload.php';

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "Running Roles and Permissions Seeder...\n\n";

try {
    $seeder = new \Database\Seeders\RolesAndPermissionsSeeder();
    $seeder->run();
    echo "✓ Seeder completed successfully!\n";
} catch (Exception $e) {
    echo "✗ Seeder failed: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}




