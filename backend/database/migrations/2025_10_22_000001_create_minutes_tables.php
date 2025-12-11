<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // Main minutes table
        Schema::create('minutes', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->date('meeting_date');
            $table->time('meeting_time');
            $table->enum('meeting_type', ['Virtual', 'Physical', 'Hybrid'])->default('Physical');
            $table->string('location')->nullable();
            $table->boolean('is_online')->default(false);
            $table->string('online_link')->nullable();
            $table->longText('notes')->nullable();
            $table->longText('summary')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();

            $table->foreign('created_by')->references('id')->on('members')->onDelete('set null');
        });

        // Attendees table
        Schema::create('minute_attendees', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('minute_id');
            $table->unsignedBigInteger('member_id');
            $table->enum('status', ['present', 'absent_with_apology', 'absent_without_apology'])->default('present');
            $table->timestamps();

            $table->foreign('minute_id')->references('id')->on('minutes')->onDelete('cascade');
            $table->foreign('member_id')->references('id')->on('members')->onDelete('cascade');
            $table->unique(['minute_id', 'member_id']);
        });

        // Agenda items table
        Schema::create('minute_agenda_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('minute_id');
            $table->string('title');
            $table->longText('notes')->nullable();
            $table->integer('order')->default(0);
            $table->json('attachments')->nullable();
            $table->timestamps();

            $table->foreign('minute_id')->references('id')->on('minutes')->onDelete('cascade');
        });

        // Action items table
        Schema::create('minute_action_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('minute_id');
            $table->text('description');
            $table->unsignedBigInteger('responsible_member_id')->nullable();
            $table->date('due_date')->nullable();
            $table->enum('status', ['Pending', 'In progress', 'Done'])->default('Pending');
            $table->timestamps();

            $table->foreign('minute_id')->references('id')->on('minutes')->onDelete('cascade');
            $table->foreign('responsible_member_id')->references('id')->on('members')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('minute_action_items');
        Schema::dropIfExists('minute_agenda_items');
        Schema::dropIfExists('minute_attendees');
        Schema::dropIfExists('minutes');
    }
};





