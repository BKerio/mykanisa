<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class BirthdayMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $firstName;
    public string $congregation;

    public function __construct(string $firstName, string $congregation)
    {
        $this->firstName = $firstName;
        $this->congregation = $congregation;
    }

    public function build()
    {
        return $this->subject('Happy Birthday from PCEA')
            ->view('emails.birthday')
            ->with([
                'firstName' => $this->firstName,
                'congregation' => $this->congregation,
            ]);
    }
}

















