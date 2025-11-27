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
        Schema::create('congregation_events', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('location')->nullable();
            $table->date('event_date');
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();
            $table->boolean('is_all_day')->default(false);
            $table->string('congregation'); // Store congregation name/identifier
            $table->unsignedBigInteger('created_by'); // Elder who created the event
            $table->integer('sms_sent_count')->default(0); // Track SMS notifications sent
            $table->timestamps();
            
            $table->foreign('created_by')->references('id')->on('members')->onDelete('cascade');
            $table->index(['congregation', 'event_date']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('congregation_events');
    }
};
