<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Group;

class GroupsSeeder extends Seeder
{
    public function run()
    {
        $groups = [
            ['name' => 'Session – Governing council of elders', 'description' => null],
            ['name' => 'PCMF (Men Fellowship)', 'description' => null],
            ['name' => 'Guild (Women Fellowship)', 'description' => null],
            ['name' => 'Youth Fellowship', 'description' => null],
            ['name' => 'Church School (Sunday school)', 'description' => null],
            ['name' => 'Health Board', 'description' => null],
            ['name' => 'JPRC (Justice, Peace & Reconciliation Committee)', 'description' => null],
            ['name' => 'Nendeni (Mission & Evangelism)', 'description' => null],
            ['name' => 'Choir', 'description' => null],
            ['name' => 'Praise & Worship Team', 'description' => null],
            ['name' => 'Brigade (Boys & Girls Brigade)', 'description' => null],
            ['name' => 'Rungiri', 'description' => null],
            ['name' => 'TEE (Theological Education by Extension)', 'description' => null],
        ];

        foreach ($groups as $g) {
            Group::firstOrCreate(['name' => $g['name']], ['description' => $g['description']]);
        }
    }
}
