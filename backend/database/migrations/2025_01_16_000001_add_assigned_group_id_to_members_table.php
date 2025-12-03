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
        Schema::table('members', function (Blueprint $table) {
            $table->foreignId('assigned_group_id')->nullable()->after('role')->constrained('groups')->nullOnDelete();
            $table->index('assigned_group_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('members', function (Blueprint $table) {
            $table->dropForeign(['assigned_group_id']);
            $table->dropIndex(['assigned_group_id']);
            $table->dropColumn('assigned_group_id');
        });
    }
};



