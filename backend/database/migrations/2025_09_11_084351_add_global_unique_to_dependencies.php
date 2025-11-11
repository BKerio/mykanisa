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
        Schema::table('dependencies', function (Blueprint $table) {
            // Avoid adding unique constraints to prevent migration failure on existing duplicates.
            // Duplicate prevention will be handled at application level in the controller.
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('dependencies', function (Blueprint $table) {
            // no-op
        });
    }
};
