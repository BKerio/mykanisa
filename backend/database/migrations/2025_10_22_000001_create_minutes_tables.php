<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('minutes', function (Blueprint $table) {
            $table->id();
            $table->string('meeting_type');
            $table->date('meeting_date');
            $table->string('minute_number')->unique();
            $table->string('agenda_title_filter')->nullable();
            $table->longText('content')->nullable();
            $table->json('agendas_json');
            $table->json('agenda_details_json')->nullable();
            $table->unsignedBigInteger('created_by_user_id')->nullable();
            $table->string('congregation')->nullable();
            $table->timestamps();
        });

        Schema::create('minute_attendees', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('minute_id');
            $table->unsignedBigInteger('member_id');
            $table->enum('status', ['present', 'apology']);
            $table->timestamps();

            $table->unique(['minute_id', 'member_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('minute_attendees');
        Schema::dropIfExists('minutes');
    }
};





