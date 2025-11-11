<?php

require_once 'vendor/autoload.php';

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "========================================\n";
echo "Running Fresh Migration\n";
echo "========================================\n\n";

try {
    // Get the migration command
    $migrator = app('migrator');
    
    // Drop all tables first
    echo "Dropping all tables...\n";
    $migrator->setConnection(null);
    $migrator->dropAllTables();
    echo "✓ All tables dropped successfully.\n\n";
    
    // Run all migrations
    echo "Running migrations...\n";
    $migrator->run([database_path('migrations')]);
    
    echo "\n========================================\n";
    echo "✓ Migration completed successfully!\n";
    echo "========================================\n";
    
    // Show migration status
    echo "\nMigration Status:\n";
    $migrations = $migrator->getRepository()->getRan();
    echo "Total migrations run: " . count($migrations) . "\n";
    
} catch (Exception $e) {
    echo "\n✗ Migration failed: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}

