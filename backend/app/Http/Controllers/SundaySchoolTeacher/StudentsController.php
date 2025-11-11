<?php

namespace App\Http\Controllers\SundaySchoolTeacher;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Member;

class StudentsController extends Controller
{
    public function index(Request $request)
    {
        // For now reuse members as students list (filter by age/flag in future)
        $students = Member::query()->latest()->paginate(20);
        return response()->json($students);
    }

    public function show(Member $student)
    {
        return response()->json($student);
    }

    public function store(Request $request)
    {
        // Placeholder: In future, attach a student profile or tag
        $validated = $request->validate([
            'member_id' => 'required|exists:members,id',
        ]);
        return response()->json(['status' => 201, 'message' => 'Student tagged'], 201);
    }

    public function update(Request $request, Member $student)
    {
        // Placeholder update
        return response()->json(['status' => 200, 'student' => $student]);
    }
}






