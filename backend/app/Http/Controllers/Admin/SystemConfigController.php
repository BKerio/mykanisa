<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemConfig;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SystemConfigController extends Controller
{
    /**
     * Get all system configurations
     */
    public function index(Request $request)
    {
        $query = SystemConfig::query();

        // Filter by category
        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('key', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $configs = $query->orderBy('category')
                        ->orderBy('key')
                        ->get();

        // Don't expose encrypted values directly - show masked version
        $configs = $configs->map(function($config) {
            $data = $config->toArray();
            if ($config->is_encrypted && !empty($config->value)) {
                $value = $config->value;
                $data['value'] = str_repeat('*', min(strlen($value), 20)) . (strlen($value) > 20 ? '...' : '');
                $data['is_masked'] = true;
            } else {
                $data['is_masked'] = false;
            }
            return $data;
        });

        return response()->json([
            'status' => 200,
            'configs' => $configs
        ]);
    }

    /**
     * Get configuration by category
     */
    public function getByCategory(string $category)
    {
        $configs = SystemConfig::getByCategory($category);

        $configs = $configs->map(function($config) {
            $data = $config->toArray();
            if ($config->is_encrypted && !empty($config->value)) {
                $value = $config->value;
                $data['value'] = str_repeat('*', min(strlen($value), 20)) . (strlen($value) > 20 ? '...' : '');
                $data['is_masked'] = true;
            } else {
                $data['is_masked'] = false;
            }
            return $data;
        });

        return response()->json([
            'status' => 200,
            'configs' => $configs
        ]);
    }

    /**
     * Get a single configuration by key
     */
    public function show(string $key)
    {
        $config = SystemConfig::where('key', $key)->first();

        if (!$config) {
            return response()->json([
                'status' => 404,
                'message' => 'Configuration not found'
            ], 404);
        }

        $data = $config->toArray();
        if ($config->is_encrypted && !empty($config->value)) {
            $value = $config->value;
            $data['value'] = str_repeat('*', min(strlen($value), 20)) . (strlen($value) > 20 ? '...' : '');
            $data['is_masked'] = true;
        } else {
            $data['is_masked'] = false;
        }

        return response()->json([
            'status' => 200,
            'config' => $data
        ]);
    }

    /**
     * Update a configuration
     */
    public function update(Request $request, string $key)
    {
        $config = SystemConfig::where('key', $key)->first();

        if (!$config) {
            return response()->json([
                'status' => 404,
                'message' => 'Configuration not found'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'value' => 'required',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 422,
                'errors' => $validator->errors()
            ], 422);
        }

        // Update value - handle type casting
        $value = $request->value;
        if ($config->type === 'boolean') {
            $value = filter_var($value, FILTER_VALIDATE_BOOLEAN) ? 'true' : 'false';
        }
        
        $config->value = $value;
        
        if ($request->has('description')) {
            $config->description = $request->description;
        }

        $config->save();

        $data = $config->toArray();
        if ($config->is_encrypted && !empty($config->value)) {
            $value = $config->value;
            $data['value'] = str_repeat('*', min(strlen($value), 20)) . (strlen($value) > 20 ? '...' : '');
            $data['is_masked'] = true;
        } else {
            $data['is_masked'] = false;
        }

        return response()->json([
            'status' => 200,
            'message' => 'Configuration updated successfully',
            'config' => $data
        ]);
    }

    /**
     * Update multiple configurations (bulk update)
     */
    public function bulkUpdate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'configs' => 'required|array',
            'configs.*.key' => 'required|string',
            'configs.*.value' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 422,
                'errors' => $validator->errors()
            ], 422);
        }

        $updated = [];
        foreach ($request->configs as $configData) {
            $config = SystemConfig::where('key', $configData['key'])->first();
            
            if ($config) {
                // Handle type casting
                $value = $configData['value'];
                if ($config->type === 'boolean') {
                    $value = filter_var($value, FILTER_VALIDATE_BOOLEAN) ? 'true' : 'false';
                }
                
                $config->value = $value;
                if (isset($configData['description'])) {
                    $config->description = $configData['description'];
                }
                $config->save();
                $updated[] = $config->key;
            }
        }

        return response()->json([
            'status' => 200,
            'message' => 'Configurations updated successfully',
            'updated' => $updated
        ]);
    }

    /**
     * Create a new configuration
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'key' => 'required|string|unique:system_configs,key',
            'value' => 'required',
            'type' => 'required|string|in:string,number,integer,float,boolean,json',
            'category' => 'required|string',
            'description' => 'nullable|string',
            'is_encrypted' => 'boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 422,
                'errors' => $validator->errors()
            ], 422);
        }

        $config = SystemConfig::create([
            'key' => $request->key,
            'value' => $request->value,
            'type' => $request->type,
            'category' => $request->category,
            'description' => $request->description,
            'is_encrypted' => $request->is_encrypted ?? false,
        ]);

        return response()->json([
            'status' => 201,
            'message' => 'Configuration created successfully',
            'config' => $config
        ], 201);
    }

    /**
     * Delete a configuration
     */
    public function destroy(string $key)
    {
        $config = SystemConfig::where('key', $key)->first();

        if (!$config) {
            return response()->json([
                'status' => 404,
                'message' => 'Configuration not found'
            ], 404);
        }

        // Prevent deletion of critical SMS configs
        $criticalKeys = ['sms_api_url', 'sms_api_key', 'sms_provider'];
        if (in_array($key, $criticalKeys)) {
            return response()->json([
                'status' => 403,
                'message' => 'Cannot delete critical configuration'
            ], 403);
        }

        $config->delete();

        return response()->json([
            'status' => 200,
            'message' => 'Configuration deleted successfully'
        ]);
    }
}

