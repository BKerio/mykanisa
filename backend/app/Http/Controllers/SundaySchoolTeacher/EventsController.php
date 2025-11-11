<?php

namespace App\Http\Controllers\SundaySchoolTeacher;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class EventsController extends Controller
{
    public function index()
    {
        return response()->json(['data' => []]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'date' => 'required|date',
            'description' => 'nullable|string',
        ]);
        return response()->json(['status' => 201, 'event' => $validated]);
    }

    public function show($event)
    {
        return response()->json(['id' => $event]);
    }

    public function update(Request $request, $event)
    {
        return response()->json(['status' => 200, 'id' => $event]);
    }

    public function destroy($event)
    {
        return response()->json(['status' => 200, 'deleted' => $event]);
    }
}






