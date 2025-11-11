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
            $table->string('birth_cert_number', 9)->nullable()->after('year_of_birth');
            $table->index('birth_cert_number');
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
            $table->dropIndex(['birth_cert_number']);
            $table->dropColumn('birth_cert_number');
        });
    }
};
