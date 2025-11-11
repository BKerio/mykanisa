<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

return new class extends Migration
{
    public function up()
    {
        // Idempotent insert
        $exists = DB::table('admins')->where('email', 'admin@pcea.com')->exists();
        if (!$exists) {
            DB::table('admins')->insert([
                'name' => 'System Admin',
                'email' => 'admin@pcea.com',
                'password' => Hash::make('1233456'),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down()
    {
        DB::table('admins')->where('email', 'admin@pcea.com')->delete();
    }
};









