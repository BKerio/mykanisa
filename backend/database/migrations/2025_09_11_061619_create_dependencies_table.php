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
        Schema::create('dependencies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('member_id')->constrained('members')->onDelete('cascade');
            $table->string('name');
            $table->integer('year_of_birth');
            $table->boolean('is_baptized')->default(false);
            $table->boolean('takes_holy_communion')->default(false);
            $table->string('school')->nullable();
            $table->timestamps();
            
            // Unique constraint to prevent duplicate dependents
            $table->unique(['member_id', 'name', 'year_of_birth'], 'unique_dependent');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('dependencies');
    }
};
