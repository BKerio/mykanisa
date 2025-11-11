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
        Schema::table('payments', function (Blueprint $table) {
            // Add unique constraints to prevent duplicate transactions
            $table->unique('checkout_request_id', 'payments_checkout_request_id_unique');
            $table->unique('mpesa_receipt_number', 'payments_mpesa_receipt_number_unique');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('payments', function (Blueprint $table) {
            // Remove unique constraints
            $table->dropUnique('payments_checkout_request_id_unique');
            $table->dropUnique('payments_mpesa_receipt_number_unique');
        });
    }
};
