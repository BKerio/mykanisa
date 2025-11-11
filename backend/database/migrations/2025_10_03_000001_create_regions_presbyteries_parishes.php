<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('regions', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });

        Schema::create('presbyteries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('region_id')->constrained('regions')->cascadeOnDelete();
            $table->string('name');
            $table->timestamps();
            $table->unique(['region_id','name']);
        });

        Schema::create('parishes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('presbytery_id')->constrained('presbyteries')->cascadeOnDelete();
            $table->string('name');
            $table->timestamps();
            $table->unique(['presbytery_id','name']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('parishes');
        Schema::dropIfExists('presbyteries');
        Schema::dropIfExists('regions');
    }
};


