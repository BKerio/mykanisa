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
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('member_id')->nullable();
            $table->string('e_kanisa_number')->index();
            $table->string('full_name');
            $table->string('congregation')->nullable();
            $table->string('event_type')->nullable(); // e.g., "Sunday Service", "Holy Communion"
            $table->date('event_date');
            $table->timestamp('scanned_at');
            $table->timestamps();

            // Foreign key constraint (optional, but good for integrity)
            // Making member_id nullable in case member is deleted but we want to keep attendance
            $table->foreign('member_id')->references('id')->on('members')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('attendances');
    }
};
