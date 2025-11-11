<?php

namespace App\Mail;

use App\Models\Member;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class WelcomeMemberMail extends Mailable
{
    use Queueable, SerializesModels;

    public Member $member;

    public function __construct(Member $member)
    {
        $this->member = $member;
    }

    public function build()
    {
        return $this->subject('Welcome to My Kanisa')
            ->view('emails.welcome_member')
            ->with(['member' => $this->member]);
    }
}



