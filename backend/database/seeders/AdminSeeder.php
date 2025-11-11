<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $email = 'admin@pcea.com';
        $exists = DB::table('admins')->where('email', $email)->exists();
        if ($exists) {
            DB::table('admins')->where('email', $email)->update([
                'name' => 'System Admin',
                'password' => Hash::make('123456'),
                'updated_at' => now(),
            ]);
        } else {
            DB::table('admins')->insert([
                'name' => 'System Admin',
                'email' => $email,
                'password' => Hash::make('123456'),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}









