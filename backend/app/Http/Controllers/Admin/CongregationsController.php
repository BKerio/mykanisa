<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CongregationsController extends Controller
{
    public function index(Request $request)
    {
        $search = trim((string)$request->query('q', ''));
        $perPage = (int) $request->query('per_page', 10);

        $query = DB::table('members')
            ->select(
                DB::raw('MIN(id) as id'),
                DB::raw('congregation as name'),
                'parish',
                'presbytery',
                DB::raw('COUNT(*) as member_count')
            )
            ->whereNotNull('congregation')
            ->where('congregation', '!=', '')
            ->groupBy('congregation', 'parish', 'presbytery')
            ->orderBy('name');

        if ($search !== '') {
            $query->having(function($q) use ($search) {
                $q->orHaving('name', 'like', "%{$search}%")
                  ->orHaving('parish', 'like', "%{$search}%")
                  ->orHaving('presbytery', 'like', "%{$search}%");
            });
        }

        $rows = $query->paginate($perPage);

        return response()->json($rows);
    }
}


