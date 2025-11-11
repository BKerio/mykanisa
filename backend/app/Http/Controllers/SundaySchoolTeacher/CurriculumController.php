<?php

namespace App\Http\Controllers\SundaySchoolTeacher;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class CurriculumController extends Controller
{
    public function index()
    {
        return response()->json(['data' => []]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
        ]);
        return response()->json(['status' => 201, 'curriculum' => $validated]);
    }

    public function show($curriculum)
    {
        return response()->json(['id' => $curriculum]);
    }

    public function update(Request $request, $curriculum)
    {
        return response()->json(['status' => 200, 'id' => $curriculum]);
    }
}






