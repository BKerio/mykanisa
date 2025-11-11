<?php

use Illuminate\Database\Migrations\Migration;
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
        // Expand enum to include additional statuses
        DB::statement("ALTER TABLE `members` MODIFY `marital_status` ENUM('Single','Married (Customary)','Married (Church Wedding)','Divorced','Widow','Widower','Separated') NOT NULL");
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Revert to original set
        DB::statement("ALTER TABLE `members` MODIFY `marital_status` ENUM('Single','Married (Customary)','Married (Church Wedding)') NOT NULL");
    }
};


