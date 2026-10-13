<?php

namespace App\Mail;

use Illuminate\Mail\Mailable;

class MitraVerificationMail extends Mailable
{
    public function __construct(
        private readonly string $mailSubject,
        private readonly string $mailBody,
    ) {
    }

    public function build(): self
    {
        return $this
            ->subject($this->mailSubject)
            ->html(nl2br(e($this->mailBody)));
    }
}
