<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class MpesaService
{
    private $baseUrl;
    private $consumerKey;
    private $consumerSecret;
    private $shortcode; //Paybill (for password generation)
    private $tillno; //BuyGoods Till Number
    private $passkey;
    private $callbackUrl;

    public function __construct()
    {
        $this->baseUrl = config('mpesa.env') === 'sandbox'
            ? 'https://sandbox.safaricom.co.ke'
            : 'https://api.safaricom.co.ke';

        $this->consumerKey    = config('mpesa.consumer_key');
        $this->consumerSecret = config('mpesa.consumer_secret');
        $this->shortcode      = config('mpesa.shortcode');
        $this->tillno         = config('mpesa.tillno');    
        $this->passkey        = config('mpesa.passkey');
        $this->callbackUrl    = config('mpesa.callback_url');
    }

    private function getAccessToken()
    {
        $response = Http::withBasicAuth($this->consumerKey, $this->consumerSecret)
            ->get($this->baseUrl . '/oauth/v1/generate?grant_type=client_credentials');

        return $response->json()['access_token'] ?? null;
    }

    public function stkPush($phone, $amount, $reference = 'Payment')
    {
        //converting m-pesa phone number to 2547XXXXXXXX format
        $phone = preg_replace('/^0/', '254', $phone);
        $phone = ltrim($phone, '+');

        $timestamp = now()->format('YmdHis');
        $password  = base64_encode($this->shortcode . $this->passkey . $timestamp);

        $token = $this->getAccessToken();

        $payload = [
            "BusinessShortCode" => $this->shortcode,      // Paybill used in password
            "Password"          => $password,
            "Timestamp"         => $timestamp,
            //"TransactionType"   => "CustomerBuyGoodsOnline",//For Till payments
            "TransactionType"   => "CustomerPayBillOnline",//For Paybill payments(sandbox)
            "Amount"            => $amount,
            "PartyA"            => $phone,//m-pesa number
            "PartyB"            => $this->tillno,//Till Number
            "PhoneNumber"       => $phone,//same as PartyA
            "CallBackURL"       => $this->callbackUrl,
            "AccountReference"  => $reference, 
            "TransactionDesc"   => $reference,
        ];

        $response = Http::withToken($token)
            ->post($this->baseUrl . '/mpesa/stkpush/v1/processrequest', $payload);

        return $response->json();
    }
}
