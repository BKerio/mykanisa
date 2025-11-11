<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Contribution;
use App\Models\Member;
use App\Models\Payment;
use Carbon\Carbon;

class ContributionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Get some existing members
        $members = Member::take(10)->get();
        
        if ($members->isEmpty()) {
            $this->command->warn('No members found. Please seed members first.');
            return;
        }

        $contributionTypes = ['general', 'tithe', 'offering', 'building_fund', 'mission', 'youth', 'women', 'men'];
        $paymentMethods = ['mpesa', 'cash', 'bank_transfer'];
        $statuses = ['completed', 'pending', 'failed'];

        // Create sample contributions for the last 3 months
        for ($i = 0; $i < 50; $i++) {
            $member = $members->random();
            $contributionDate = Carbon::now()->subDays(rand(1, 90));
            
            // Create a payment record first
            $payment = Payment::create([
                'merchant_request_id' => 'REQ' . str_pad($i + 1, 8, '0', STR_PAD_LEFT),
                'checkout_request_id' => 'CHK' . str_pad($i + 1, 8, '0', STR_PAD_LEFT),
                'account_reference' => $member->e_kanisa_number . '_' . $contributionDate->format('Ymd'),
                'phone' => $member->telephone ?? '254700000000',
                'amount' => rand(100, 5000),
                'mpesa_receipt_number' => 'MPE' . str_pad($i + 1, 8, '0', STR_PAD_LEFT),
                'result_code' => '0',
                'result_desc' => 'The service request is processed successfully.',
                'status' => 'confirmed',
                'member_id' => $member->id,
            ]);

            // Create the contribution
            Contribution::create([
                'member_id' => $member->id,
                'payment_id' => $payment->id,
                'contribution_type' => $contributionTypes[array_rand($contributionTypes)],
                'amount' => $payment->amount,
                'description' => 'Church contribution - ' . ucfirst($contributionTypes[array_rand($contributionTypes)]),
                'contribution_date' => $contributionDate,
                'payment_method' => $paymentMethods[array_rand($paymentMethods)],
                'reference_number' => $payment->mpesa_receipt_number,
                'status' => $statuses[array_rand($statuses)],
                'notes' => 'Sample contribution data for testing',
            ]);
        }

        $this->command->info('Created 50 sample contributions.');
    }
}
