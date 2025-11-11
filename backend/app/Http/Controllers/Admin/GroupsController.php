<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Group;

class GroupsController extends Controller
{
    public function index(Request $request)
    {
        $query = Group::query()->orderBy('name');
        if ($search = $request->query('q')) {
            $query->where('name', 'like', "%{$search}%");
        }
        $groups = $query->paginate($request->integer('per_page', 20));
        return response()->json($groups);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:groups,name',
            'description' => 'nullable|string',
        ]);
        $group = Group::create($validated);
        return response()->json(['status' => 201, 'group' => $group], 201);
    }

    public function show(Group $group)
    {
        return response()->json($group);
    }

    public function update(Request $request, Group $group)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:groups,name,' . $group->id,
            'description' => 'nullable|string',
        ]);
        $group->update($validated);
        return response()->json(['status' => 200, 'group' => $group]);
    }

    public function destroy(Group $group)
    {
        $group->delete();
        return response()->json(['status' => 200, 'message' => 'Group deleted']);
    }
}
