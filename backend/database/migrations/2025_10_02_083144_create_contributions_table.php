<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('contributions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('member_id')->constrained('members')->onDelete('cascade');
            $table->foreignId('payment_id')->nullable()->constrained('payments')->onDelete('set null');
            $table->string('contribution_type')->default('general'); // general, tithe, offering, building_fund, etc.
            $table->decimal('amount', 10, 2);
            $table->string('description')->nullable();
            $table->date('contribution_date');
            $table->string('payment_method')->default('mpesa'); // mpesa, cash, bank_transfer, etc.
            $table->string('reference_number')->nullable(); // M-Pesa receipt number or other reference
            $table->enum('status', ['pending', 'completed', 'failed', 'cancelled'])->default('completed');
            $table->text('notes')->nullable();
            $table->timestamps();
            
            // Indexes for better performance
            $table->index(['member_id', 'contribution_date']);
            $table->index(['contribution_type', 'contribution_date']);
            $table->index('reference_number');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('contributions');
    }
};
