<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('members', function (Blueprint $table) {
            $table->id();
            $table->string('full_name');
            $table->date('date_of_birth');
            $table->integer('age')->nullable(); // Auto-calculated
            $table->string('national_id')->nullable(); // Required if 18+
            $table->string('email')->unique();
            $table->enum('gender', ['Male', 'Female']);
            $table->enum('marital_status', ['Single', 'Married (Customary)', 'Married (Church Wedding)']);
            $table->string('primary_school')->nullable();
            $table->boolean('is_baptized')->default(false);
            $table->boolean('takes_holy_communion')->default(false);
            
            // Church details
            $table->string('presbytery');
            $table->string('parish');
            $table->string('congregation');
            
            // E-kanisa number
            $table->string('e_kanisa_number')->unique();
            
            // Contact details
            $table->string('telephone')->nullable();
            $table->string('location_county')->nullable();
            $table->string('location_subcounty')->nullable();
            
            // System fields
            $table->boolean('is_active')->default(true);
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamps();
            
            // Indexes
            $table->index(['presbytery', 'parish', 'congregation']);
            $table->index('e_kanisa_number');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('members');
    }
};
