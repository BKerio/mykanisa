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
        Schema::create('pledges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('member_id')->constrained('members')->onDelete('cascade');
            $table->string('account_type'); // Tithe, Offering, Development, Thanksgiving, FirstFruit, Others
            $table->decimal('pledge_amount', 10, 2); // Total amount pledged
            $table->decimal('remaining_amount', 10, 2); // Remaining amount to fulfill
            $table->decimal('fulfilled_amount', 10, 2)->default(0); // Amount already contributed
            $table->date('pledge_date'); // When the pledge was made
            $table->date('target_date')->nullable(); // Optional target date to fulfill by
            $table->text('description')->nullable(); // Optional description
            $table->enum('status', ['active', 'fulfilled', 'cancelled'])->default('active');
            $table->timestamps();
            
            // Indexes for better performance
            $table->index(['member_id', 'status']);
            $table->index(['account_type', 'status']);
            $table->index('pledge_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pledges');
    }
};

