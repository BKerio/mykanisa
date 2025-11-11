<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('members', function (Blueprint $table) {
            if (!Schema::hasColumn('members', 'region')) {
                $table->string('region')->after('takes_holy_communion');
            }
            if (!Schema::hasColumn('members', 'district')) {
                $table->string('district')->after('parish');
            }
            if (Schema::hasColumn('members', 'location_county')) {
                $table->dropColumn('location_county');
            }
            if (Schema::hasColumn('members', 'location_subcounty')) {
                $table->dropColumn('location_subcounty');
            }
        });
    }

    public function down()
    {
        Schema::table('members', function (Blueprint $table) {
            if (Schema::hasColumn('members', 'region')) {
                $table->dropColumn('region');
            }
            if (Schema::hasColumn('members', 'district')) {
                $table->dropColumn('district');
            }
            if (!Schema::hasColumn('members', 'location_county')) {
                $table->string('location_county')->nullable();
            }
            if (!Schema::hasColumn('members', 'location_subcounty')) {
                $table->string('location_subcounty')->nullable();
            }
        });
    }
};


