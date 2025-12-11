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
        Schema::table('minute_action_items', function (Blueprint $table) {
            if (!Schema::hasColumn('minute_action_items', 'status_reason')) {
                $table->text('status_reason')->nullable()->after('status');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('minute_action_items', function (Blueprint $table) {
            $table->dropColumn('status_reason');
        });
    }
};
