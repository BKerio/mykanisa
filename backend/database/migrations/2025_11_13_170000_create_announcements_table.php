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
        Schema::create('announcements', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('message');
            $table->enum('type', ['broadcast', 'individual', 'group'])->default('broadcast');
            $table->foreignId('sent_by')->constrained('members')->onDelete('cascade');
            $table->foreignId('recipient_id')->nullable()->constrained('members')->onDelete('cascade');
            $table->boolean('is_priority')->default(false);
            $table->integer('target_count')->default(0);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
            
            // Indexes
            $table->index('sent_by');
            $table->index('recipient_id');
            $table->index('type');
            $table->index('is_priority');
            $table->index('created_at');
        });

        // Create pivot table for announcements read by members
        Schema::create('announcement_reads', function (Blueprint $table) {
            $table->id();
            $table->foreignId('announcement_id')->constrained('announcements')->onDelete('cascade');
            $table->foreignId('member_id')->constrained('members')->onDelete('cascade');
            $table->timestamp('read_at')->useCurrent();
            $table->timestamps();
            
            $table->unique(['announcement_id', 'member_id']);
            $table->index('member_id');
            $table->index('announcement_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('announcement_reads');
        Schema::dropIfExists('announcements');
    }
};

