<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Crypt;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('system_configs', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->string('type')->default('string'); // string, number, boolean, json
            $table->string('category')->default('general'); // sms, email, payment, general
            $table->text('description')->nullable();
            $table->boolean('is_encrypted')->default(false);
            $table->timestamps();
        });

        // Insert default SMS configuration
        DB::table('system_configs')->insert([
            [
                'key' => 'sms_provider',
                'value' => 'fornax',
                'type' => 'string',
                'category' => 'sms',
                'description' => 'SMS Provider name (advanta, fornax, twilio, etc.)',
                'is_encrypted' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'sms_api_url',
                'value' => 'https://bulksms.fornax-technologies.com/api/services/sendsms/',
                'type' => 'string',
                'category' => 'sms',
                'description' => 'SMS API endpoint URL',
                'is_encrypted' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'sms_api_key',
                'value' => Crypt::encryptString('9af6688adb82a80faa17c5066ab12b20'),
                'type' => 'string',
                'category' => 'sms',
                'description' => 'SMS API Key',
                'is_encrypted' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'sms_partner_id',
                'value' => '4889',
                'type' => 'string',
                'category' => 'sms',
                'description' => 'SMS Partner ID',
                'is_encrypted' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'sms_shortcode',
                'value' => 'P.C.E.A_SGM',
                'type' => 'string',
                'category' => 'sms',
                'description' => 'SMS Shortcode/Sender ID',
                'is_encrypted' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'sms_enabled',
                'value' => 'true',
                'type' => 'boolean',
                'category' => 'sms',
                'description' => 'Enable or disable SMS service',
                'is_encrypted' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('system_configs');
    }
};

