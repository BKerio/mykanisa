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
            if (!Schema::hasColumn('dependencies', 'image')) {
                $table->string('image')->nullable()->after('school');
            }
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
            if (Schema::hasColumn('dependencies', 'image')) {
                $table->dropColumn('image');
            }
        });
    }
};
