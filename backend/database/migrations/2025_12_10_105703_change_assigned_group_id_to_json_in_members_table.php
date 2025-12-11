<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (!Schema::hasColumn('members', 'assigned_group_ids')) {
            Schema::table('members', function (Blueprint $table) {
                $table->json('assigned_group_ids')->nullable()->after('assigned_group_id');
            });

            // Migrate existing data
            $members = DB::table('members')->whereNotNull('assigned_group_id')->get();
            foreach ($members as $member) {
                DB::table('members')
                    ->where('id', $member->id)
                    ->update(['assigned_group_ids' => json_encode([(int)$member->assigned_group_id])]);
            }
        }

        if (Schema::hasColumn('members', 'assigned_group_id')) {
            Schema::table('members', function (Blueprint $table) {
                // Check if foreign key exists before dropping it ? 
                // It's hard to check constraint name reliably, but typically it follows convention.
                // We'll try-catch or just proceed. But schema builder usually handles dropForeign by name.
                // We previously used array syntax which guesses the index name.
                
                try {
                     $table->dropForeign(['assigned_group_id']);
                } catch (\Exception $e) {
                    // Ignore if FK doesn't exist
                }
                $table->dropColumn('assigned_group_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('members', function (Blueprint $table) {
            $table->unsignedBigInteger('assigned_group_id')->nullable()->after('role');
        });

        // Restore data (take first group ID if multiple exist)
        $members = DB::table('members')->whereNotNull('assigned_group_ids')->get();
        foreach ($members as $member) {
            $groupIds = json_decode($member->assigned_group_ids, true);
            if (!empty($groupIds)) {
                DB::table('members')
                    ->where('id', $member->id)
                    ->update(['assigned_group_id' => $groupIds[0]]);
            }
        }

        Schema::table('members', function (Blueprint $table) {
            $table->dropColumn('assigned_group_ids');
        });
    }
};
