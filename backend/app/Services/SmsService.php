<?php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Log;

class SmsService
{
    protected Client $httpClient;

    public function __construct(?Client $client = null)
    {
        $this->httpClient = $client ?: new Client([
            'timeout' => 10,
        ]);
    }

    public function sendSms(string $phoneNumber, string $message): bool
    {
        try {
            $msisdn = $this->normalizeMsisdn($phoneNumber);

            $payload = [
                'apikey'    => '9af6688adb82a80faa17c5066ab12b20',
                'partnerID' => '4889',
                'message'   => $message,
                'shortcode' => 'P.C.E.A_SGM',
                'mobile'    => $msisdn,
                'msisdn'    => $msisdn,
            ];

            $response = $this->httpClient->post(
                'https://bulksms.fornax-technologies.com/api/services/sendsms/',
                [
                    'form_params' => $payload,
                    'headers' => [
                        'Accept' => 'application/json',
                    ],
                ]
            );

            $statusOk = $response->getStatusCode() >= 200 && $response->getStatusCode() < 300;
            $body = (string) $response->getBody();
            $bodyArray = json_decode($body, true);

            Log::info('AdvantaSMS response', [
                'status' => $response->getStatusCode(),
                'body'   => $body,
                'success' => $statusOk && (isset($bodyArray['success']) ? $bodyArray['success'] : $statusOk)
            ]);

            // Check if response indicates success
            $success = $statusOk;
            if (is_array($bodyArray) && isset($bodyArray['success'])) {
                $success = $bodyArray['success'];
            } elseif (is_array($bodyArray) && isset($bodyArray['status']) && $bodyArray['status'] === 'success') {
                $success = true;
            }

            return $success;
        } catch (\Throwable $e) {
            Log::error('SMS send failed: ' . $e->getMessage());
            return false;
        }
    }

    protected function normalizeMsisdn(string $phoneNumber): string
    {
        $digits = preg_replace('/[^0-9]/', '', $phoneNumber);

        if (str_starts_with($digits, '0')) {

            return '254' . substr($digits, 1);
        }

        if (str_starts_with($digits, '254')) {
            return $digits;
        }

        if (str_starts_with($digits, '7') && strlen($digits) === 9) {
            return '254' . $digits;
        }
        return $digits;
    }
}
