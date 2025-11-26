<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Group;

class GroupsSeeder extends Seeder
{
    public function run()
    {
        $groups = [
            ['name' => 'Session – Governing council of elders', 'description' => 'Leads and oversees church governance and decision-making.'],
    ['name' => 'PCMF (Men Fellowship)', 'description' => 'Encourages spiritual growth and fellowship among men.'],
    ['name' => 'Guild (Women Fellowship)', 'description' => 'Fosters fellowship, prayer, and service among women.'],
    ['name' => 'Youth Fellowship', 'description' => 'Supports the spiritual, social, and personal development of youth.'],
    ['name' => 'Church School (Sunday school)', 'description' => 'Provides biblical education and moral guidance for children.'],
    ['name' => 'Health Board', 'description' => 'Oversees church health programs and promotes wellness initiatives.'],
    ['name' => 'JPRC (Justice, Peace & Reconciliation Committee)', 'description' => 'Promotes justice, peace, and conflict resolution in the community.'],
    ['name' => 'Nendeni (Mission & Evangelism)', 'description' => 'Leads outreach, evangelism, and mission activities.'],
    ['name' => 'Choir', 'description' => 'Provides musical worship and leads congregational singing.'],
    ['name' => 'Praise & Worship Team', 'description' => 'Facilitates worship through contemporary and traditional music.'],
    ['name' => 'Brigade (Boys & Girls Brigade)', 'description' => 'Develops discipline, leadership, and spiritual growth in children and teens.'],
    ['name' => 'Rungiri', 'description' => 'Engages in local community service and church support activities.'],
    ['name' => 'TEE (Theological Education by Extension)', 'description' => 'Offers theological training and education for church members.'],

        ];

        foreach ($groups as $g) {
            Group::firstOrCreate(['name' => $g['name']], ['description' => $g['description']]);
        }
    }
}
