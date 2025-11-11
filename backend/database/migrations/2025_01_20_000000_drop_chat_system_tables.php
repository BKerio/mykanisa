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
        // Drop chat system tables if they exist
        Schema::dropIfExists('chat_online_status');
        Schema::dropIfExists('chat_participants');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversations');
        Schema::dropIfExists('chat_system_tables');
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // This migration only drops tables, so down() is intentionally left empty
        // If you need to restore, you would need to recreate the tables
    }
};

