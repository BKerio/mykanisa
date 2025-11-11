<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class ResetCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public int $code;

    public function __construct(int $code)
    {
        $this->code = $code;
    }

    public function build()
    {
        return $this->subject('Your Password Reset Code')
            ->view('emails.reset_code')
            ->with(['code' => $this->code]);
    }
}


