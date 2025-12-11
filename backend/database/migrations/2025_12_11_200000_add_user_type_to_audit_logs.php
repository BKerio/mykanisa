<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('audit_logs', function (Blueprint $table) {
            $table->string('user_type')->nullable()->after('user_id');
        });

        // Backfill existing logs assuming they are Users
        DB::table('audit_logs')->whereNotNull('user_id')->update(['user_type' => 'App\Models\User']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('audit_logs', function (Blueprint $table) {
            $table->dropColumn('user_type');
        });
    }
};
