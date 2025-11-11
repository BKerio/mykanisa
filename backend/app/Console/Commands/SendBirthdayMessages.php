<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Carbon\Carbon;
use App\Models\Member;
use App\Services\SmsService;

class SendBirthdayMessages extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'birthday:send {--dry-run : Do not send SMS, just log recipients}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send happy birthday SMS messages to members whose birthday is today';

    /**
     * Execute the console command.
     */
    public function handle(SmsService $smsService): int
    {
        $today = Carbon::today();
        $month = (int) $today->format('m');
        $day = (int) $today->format('d');

        $this->info("Looking for members with birthdays on {$today->toDateString()}...");

        $members = Member::query()
            ->whereMonth('date_of_birth', $month)
            ->whereDay('date_of_birth', $day)
            ->whereNotNull('telephone')
            ->where('telephone', '!=', '')
            ->get();

        if ($members->isEmpty()) {
            $this->info('No members have birthdays today.');
            return self::SUCCESS;
        }

        $sentCount = 0;
        $skipped = 0;
        $dryRun = (bool) $this->option('dry-run');
        $dateKey = $today->format('Ymd');

        foreach ($members as $member) {
            $cacheKey = "birthday_sent:{$member->id}:{$dateKey}";
            if (Cache::has($cacheKey)) {
                $skipped++;
                continue;
            }

            $message = $this->buildMessage($member);

            if ($dryRun) {
                Log::info('DRY-RUN birthday SMS', [
                    'member_id' => $member->id,
                    'name' => $member->full_name,
                    'phone' => $member->telephone,
                    'message' => $message,
                ]);
                $sentCount++;
                // mark as sent in dry run? no.
                continue;
            }

            try {
                $ok = $smsService->sendSms($member->telephone, $message);
                if ($ok) {
                    // Cache for 24 hours to avoid duplicates the same day
                    Cache::put($cacheKey, true, now()->addDay());
                    $sentCount++;
                } else {
                    Log::warning('Failed to send birthday SMS', [
                        'member_id' => $member->id,
                        'name' => $member->full_name,
                        'phone' => $member->telephone,
                    ]);
                }

                // Send email if available
                if (!empty($member->email)) {
                    $name = trim($member->full_name);
                    $first = $name !== '' ? explode(' ', $name)[0] : 'Member';
                    $cong = $member->congregation ?: 'PCEA';
                    try {
                        Mail::to($member->email)->send(new \App\Mail\BirthdayMail($first, $cong));
                    } catch (\Throwable $e) {
                        Log::warning('Birthday email failed: '.$e->getMessage(), [
                            'member_id' => $member->id,
                            'email' => $member->email,
                        ]);
                    }
                }
            } catch (\Throwable $e) {
                Log::error('Error sending birthday SMS: '.$e->getMessage(), [
                    'member_id' => $member->id,
                ]);
            }
        }

        $this->info("Birthday SMS processed. Sent: {$sentCount}, Skipped (already sent today): {$skipped}");
        Log::info('Birthday SMS summary', [
            'date' => $today->toDateString(),
            'sent' => $sentCount,
            'skipped' => $skipped,
            'total_candidates' => $members->count(),
        ]);

        return self::SUCCESS;
    }

    protected function buildMessage(Member $member): string
    {
        $name = trim($member->full_name);
        $firstName = $name !== '' ? explode(' ', $name)[0] : 'Member';
        $congregation = $member->congregation ?: 'PCEA';
        return "Happy Birthday, {$firstName}! 🎉 From {$congregation} - wishing you God’s blessings, joy and favor today and always.";
    }
}


