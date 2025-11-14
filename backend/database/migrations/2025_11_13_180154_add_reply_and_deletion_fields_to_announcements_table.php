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
        Schema::table('announcements', function (Blueprint $table) {
            // Add reply_to field to link replies to original announcements
            $table->foreignId('reply_to')->nullable()->after('recipient_id')
                ->constrained('announcements')->onDelete('cascade');
            
            // Add deleted_by_member field to track which member deleted it (soft delete)
            $table->timestamp('deleted_by_member_at')->nullable()->after('read_at');
            $table->foreignId('deleted_by_member_id')->nullable()->after('deleted_by_member_at')
                ->constrained('members')->onDelete('set null');
            
            // Add index for reply_to
            $table->index('reply_to');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('announcements', function (Blueprint $table) {
            $table->dropForeign(['reply_to']);
            $table->dropForeign(['deleted_by_member_id']);
            $table->dropIndex(['reply_to']);
            $table->dropColumn(['reply_to', 'deleted_by_member_at', 'deleted_by_member_id']);
        });
    }
};
