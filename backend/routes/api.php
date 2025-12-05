<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\LocationController;
use App\Http\Controllers\MemberController;
use App\Http\Controllers\MpesaController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\QRController;
use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\UserController as AdminUserController;
use App\Http\Controllers\Admin\MembersController as AdminMembersController;
use App\Http\Controllers\Admin\ContributionsController as AdminContributionsController;
use App\Http\Controllers\Admin\CongregationsController as AdminCongregationsController;
use App\Http\Controllers\Admin\RolesController as AdminRolesController;
use App\Http\Controllers\Admin\PermissionsController as AdminPermissionsController;
use App\Http\Controllers\Admin\SystemConfigController as AdminSystemConfigController;
use App\Http\Controllers\Admin\AttendanceController as AdminAttendanceController;
use App\Http\Controllers\ContributionsController;
use App\Models\Member;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::post('/register', [AuthController::class, 'Register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/members/register', [MemberController::class, 'register']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/verify-reset-code', [AuthController::class, 'verifyResetCode']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

// Location endpoints (Regions > Presbyteries > Parishes)
Route::get('/regions', [LocationController::class, 'getRegions']);
Route::get('/presbyteries', [LocationController::class, 'getPresbyteries']);
Route::get('/parishes', [LocationController::class, 'getParishes']);
Route::get('/groups', [LocationController::class, 'getGroups']);

// Test profile image endpoint
Route::get('/test-profile-image/{path}', function($path) {
    $fullPath = storage_path('app/public/profiles/' . $path);
    if (file_exists($fullPath)) {
        return response()->file($fullPath);
    }
    return response()->json(['error' => 'Image not found'], 404);
})->where('path', '.*');
Route::middleware('auth:sanctum')->group(function(){
    Route::get('/members/me', [MemberController::class, 'me']);
    Route::post('/members/me', [MemberController::class, 'updateMe']);
    Route::post('/members/me/avatar', [MemberController::class, 'updateAvatar']);
    Route::post('/members/me/passport', [MemberController::class, 'updatePassport']);
    Route::get('/members/dependents', [MemberController::class, 'getDependents']);
    Route::post('/members/dependents', [MemberController::class, 'addDependent']);
    Route::put('/members/dependents/{id}', [MemberController::class, 'updateDependent']);
    Route::post('/members/dependents/{id}/image', [MemberController::class, 'updateDependentImage']);
    Route::get('/payments/me', [PaymentController::class, 'mine']);
    
    // Member group endpoints
    Route::get('/members/my-youth-leader', [\App\Http\Controllers\Member\GroupsController::class, 'getMyYouthLeader']);
    Route::post('/member/send-message-to-youth-leader', [\App\Http\Controllers\Member\GroupsController::class, 'sendMessageToYouthLeader']);
    Route::get('/groups/{groupId}/activities', [\App\Http\Controllers\Member\GroupsController::class, 'getGroupActivities']);
    
    // Contributions endpoints
    Route::get('/contributions/summary', [ContributionsController::class, 'getMemberSummary']);
    Route::get('/contributions/history', [ContributionsController::class, 'getMemberHistory']);
    Route::post('/contributions/create', [ContributionsController::class, 'createFromBreakdown']);
    Route::put('/contributions/{id}/status', [ContributionsController::class, 'updateStatus']);
    
    // Members endpoint for authenticated users (for minutes page)
    Route::get('/members', [MemberController::class, 'getMembersForMinutes']);
    
    // QR Code endpoints
    Route::get('/qr/member-data', [QRController::class, 'getMemberForQR']);
});

// Public QR verification endpoint (no auth required for scanning)
Route::post('/qr/verify', [QRController::class, 'verifyQR']);

// Public payments status endpoint for client polling by CheckoutRequestID
Route::get('/payments/status', [PaymentController::class, 'status']);

// Mpesa endpoints (must be public for Safaricom callbacks)
Route::post('/mpesa/callback', [MpesaController::class, 'callback']);
Route::post('/mpesa/stkpush', [MpesaController::class, 'stkPush']);


// Admin auth and admin-only routes
Route::prefix('admin')->group(function(){
    Route::post('/login', [AdminAuthController::class, 'login']);
    Route::middleware(['auth:sanctum','admin'])->group(function(){
        Route::get('/me', [AdminAuthController::class, 'me']);
        Route::post('/logout', [AdminAuthController::class, 'logout']);

        Route::get('/users', [AdminUserController::class, 'index']);
        Route::post('/users', [AdminUserController::class, 'store']);
        Route::get('/users/{user}', [AdminUserController::class, 'show']);
        Route::put('/users/{user}', [AdminUserController::class, 'update']);
        Route::delete('/users/{user}', [AdminUserController::class, 'destroy']);

        Route::get('/members', [AdminMembersController::class, 'index']);
        Route::get('/members/{member}', [AdminMembersController::class, 'show']);
        Route::put('/members/{member}', [AdminMembersController::class, 'update']);
        Route::delete('/members/{member}', [AdminMembersController::class, 'destroy']);

        // Congregations routes
        Route::get('/congregations', [AdminCongregationsController::class, 'index']);

        // Regions CRUD
        Route::apiResource('regions', \App\Http\Controllers\Admin\RegionsController::class);

        // Presbyteries CRUD
        Route::apiResource('presbyteries', \App\Http\Controllers\Admin\PresbyteriesController::class);

        // Parishes CRUD
        Route::apiResource('parishes', \App\Http\Controllers\Admin\ParishesController::class);

        // Contributions routes
        Route::get('/contributions', [AdminContributionsController::class, 'index']);
        Route::get('/contributions/by-congregation', [AdminContributionsController::class, 'byCongregation']);
        Route::get('/contributions/statistics', [AdminContributionsController::class, 'statistics']);
        Route::get('/contributions/{contribution}', [AdminContributionsController::class, 'show']);
        Route::get('/contributions-meta/congregations', [AdminContributionsController::class, 'congregations']);
        Route::get('/contributions-meta/types', [AdminContributionsController::class, 'types']);

        // Groups CRUD
        Route::apiResource('groups', \App\Http\Controllers\Admin\GroupsController::class);

        // System Configuration routes
        Route::prefix('system-config')->group(function(){
            Route::get('/', [AdminSystemConfigController::class, 'index']);
            Route::get('/category/{category}', [AdminSystemConfigController::class, 'getByCategory']);
            Route::get('/{key}', [AdminSystemConfigController::class, 'show']);
            Route::put('/{key}', [AdminSystemConfigController::class, 'update']);
            Route::post('/bulk-update', [AdminSystemConfigController::class, 'bulkUpdate']);
            Route::post('/', [AdminSystemConfigController::class, 'store']);
            Route::delete('/{key}', [AdminSystemConfigController::class, 'destroy']);
        });

        // Attendance routes
        Route::prefix('attendance')->group(function(){
            Route::post('/mark', [AdminAttendanceController::class, 'markAttendance']);
            Route::post('/mark-single', [AdminAttendanceController::class, 'markSingleAttendance']);
            Route::get('/', [AdminAttendanceController::class, 'getAttendance']);
        });

        // Roles and Permissions routes (Admin only)
        Route::middleware('permission:manage_roles')->group(function(){
            Route::apiResource('roles', AdminRolesController::class);
            Route::post('/roles/{role}/assign-member', [AdminRolesController::class, 'assignToMember']);
            Route::delete('/roles/{role}/remove-member', [AdminRolesController::class, 'removeFromMember']);
            Route::get('/roles/{role}/members', [AdminRolesController::class, 'members']);
            Route::get('/roles/{role}/permissions', [AdminRolesController::class, 'permissions']);
        });

        Route::middleware('permission:manage_permissions')->group(function(){
            Route::apiResource('permissions', AdminPermissionsController::class);
        });
    });
});

// Leadership routes (for members with leadership roles)
Route::middleware(['auth:sanctum', 'leadership'])->group(function(){
    Route::prefix('leadership')->group(function(){
        // Get leadership dashboard data
        Route::get('/dashboard', function(Request $request){
            $user = $request->user();
            $congregation = $request->input('congregation');
            $parish = $request->input('parish');
            $presbytery = $request->input('presbytery');
            
            // Get role from members.role field (not member_roles table)
            $memberRole = $user->role ?? 'member';
            
            // Get permissions for the role from roles table
            $role = \App\Models\Role::where('slug', $memberRole)->first();
            $permissions = $role ? $role->permissions()->get() : collect();
            
            return response()->json([
                'status' => 200,
                'user' => $user,
                'roles' => [['slug' => $memberRole, 'name' => ucfirst($memberRole)]],
                'permissions' => $permissions,
                'scope' => compact('congregation', 'parish', 'presbytery')
            ]);
        });

        // Member management for leaders
        Route::middleware('permission:view_members')->group(function(){
            Route::get('/members', [AdminMembersController::class, 'index']);
            Route::get('/members/{member}', [AdminMembersController::class, 'show']);
        });

        // Contribution management for leaders
        Route::middleware('permission:view_contributions')->group(function(){
            Route::get('/contributions', [AdminContributionsController::class, 'index']);
            Route::get('/contributions/statistics', [AdminContributionsController::class, 'statistics']);
        });

        // Role assignment for leaders (limited scope)
        Route::middleware('permission:assign_roles')->group(function(){
            Route::get('/roles', [AdminRolesController::class, 'index']);
            Route::post('/members/{member}/assign-role', function(Request $request, Member $member){
                $validated = $request->validate([
                    'role_id' => 'required|exists:roles,id',
                    'expires_at' => 'nullable|date|after:now'
                ]);

                $role = Role::findOrFail($validated['role_id']);
                $user = $request->user();
                
                // Check if user has permission to assign this role
                // Elder has full permissions - bypass check
                if (!$user->hasRole('elder') && !$user->hasPermission('assign_roles')) {
                    return response()->json(['message' => 'Insufficient permissions'], 403);
                }

                // Get scope from authenticated user's context
                $congregation = $request->input('congregation') ?? $user->congregation;
                $parish = $request->input('parish') ?? $user->parish;
                $presbytery = $request->input('presbytery') ?? $user->presbytery;

                $success = $member->assignRole(
                    $role,
                    $congregation,
                    $parish,
                    $presbytery,
                    $validated['expires_at'] ?? null
                );

                if ($success) {
                    return response()->json([
                        'status' => 200,
                        'message' => "Role '{$role->name}' assigned to member successfully"
                    ]);
                }

                return response()->json([
                    'status' => 500,
                    'message' => 'Failed to assign role to member'
                ], 500);
            });
        });
    });
});

// Role-specific routes
// Pastor routes
Route::middleware(['auth:sanctum', 'role:pastor'])->group(function(){
    Route::prefix('pastor')->group(function(){
        Route::get('/me', [\App\Http\Controllers\Pastor\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Pastor\AuthController::class, 'logout']);
        
        Route::get('/members', [\App\Http\Controllers\Pastor\MembersController::class, 'index']);
        Route::post('/members', [\App\Http\Controllers\Pastor\MembersController::class, 'store']);
        Route::get('/members/{member}', [\App\Http\Controllers\Pastor\MembersController::class, 'show']);
        Route::put('/members/{member}', [\App\Http\Controllers\Pastor\MembersController::class, 'update']);
        
        Route::get('/contributions', [\App\Http\Controllers\Pastor\ContributionsController::class, 'index']);
        Route::post('/contributions', [\App\Http\Controllers\Pastor\ContributionsController::class, 'store']);
        Route::get('/contributions/{contribution}', [\App\Http\Controllers\Pastor\ContributionsController::class, 'show']);
        Route::get('/contributions-statistics', [\App\Http\Controllers\Pastor\ContributionsController::class, 'statistics']);
    });
});

// Elder routes (also accessible to secretaries)
Route::middleware(['auth:sanctum', 'role:elder|secretary'])->group(function(){
    Route::prefix('elder')->group(function(){
        Route::get('/me', [\App\Http\Controllers\Elder\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Elder\AuthController::class, 'logout']);
        
        Route::get('/members', [\App\Http\Controllers\Elder\MembersController::class, 'index']);
        Route::post('/members', [\App\Http\Controllers\Elder\MembersController::class, 'store']);
        Route::get('/members/{member}', [\App\Http\Controllers\Elder\MembersController::class, 'show']);
        Route::put('/members/{member}', [\App\Http\Controllers\Elder\MembersController::class, 'update']);
        Route::delete('/members/{member}', [\App\Http\Controllers\Elder\MembersController::class, 'destroy']);
        
        Route::get('/contributions', [\App\Http\Controllers\Elder\ContributionsController::class, 'index']);
        Route::get('/contributions/by-congregation', [\App\Http\Controllers\Elder\ContributionsController::class, 'byCongregation']);
        Route::get('/contributions/statistics', [\App\Http\Controllers\Elder\ContributionsController::class, 'statistics']);
        Route::get('/contributions/{payment}', [\App\Http\Controllers\Elder\ContributionsController::class, 'show']);
        Route::get('/contributions-meta/congregations', [\App\Http\Controllers\Elder\ContributionsController::class, 'congregations']);
        Route::get('/contributions-meta/types', [\App\Http\Controllers\Elder\ContributionsController::class, 'types']);
        Route::get('/contributions-meta/congregations-with-locations', [\App\Http\Controllers\Elder\ContributionsController::class, 'congregationsWithLocations']);
        Route::get('/contributions/total', [\App\Http\Controllers\Elder\ContributionsController::class, 'total']);
        
        // Messages/Announcements routes
        Route::post('/messages', [\App\Http\Controllers\Elder\MessagesController::class, 'store']);
        Route::get('/messages', [\App\Http\Controllers\Elder\MessagesController::class, 'index']);
        Route::get('/messages/{announcement}', [\App\Http\Controllers\Elder\MessagesController::class, 'show']);
        Route::post('/communications/broadcast', [\App\Http\Controllers\Elder\MessagesController::class, 'broadcast']);
        Route::get('/messages-from-members', [\App\Http\Controllers\Elder\MessagesController::class, 'messagesFromMembers']);
        Route::post('/messages/{announcement}/reply', [\App\Http\Controllers\Elder\MessagesController::class, 'replyToMember']);
        Route::post('/messages/{announcement}/mark-read', [\App\Http\Controllers\Elder\MessagesController::class, 'markAsRead']);
        Route::get('/messages/unread-count', [\App\Http\Controllers\Elder\MessagesController::class, 'unreadCount']);
        
        // Events routes
        Route::get('/events', [\App\Http\Controllers\Elder\EventsController::class, 'index']);
        Route::post('/events', [\App\Http\Controllers\Elder\EventsController::class, 'store']);
        Route::get('/events/{event}', [\App\Http\Controllers\Elder\EventsController::class, 'show']);
        Route::put('/events/{event}', [\App\Http\Controllers\Elder\EventsController::class, 'update']);
        Route::delete('/events/{event}', [\App\Http\Controllers\Elder\EventsController::class, 'destroy']);
    });
});

// Deacon routes
Route::middleware(['auth:sanctum', 'role:deacon'])->group(function(){
    Route::prefix('deacon')->group(function(){
        Route::get('/me', [\App\Http\Controllers\Deacon\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Deacon\AuthController::class, 'logout']);
        
        Route::get('/members', [\App\Http\Controllers\Deacon\MembersController::class, 'index']);
        Route::post('/members', [\App\Http\Controllers\Deacon\MembersController::class, 'store']);
        Route::get('/members/{member}', [\App\Http\Controllers\Deacon\MembersController::class, 'show']);
        
        Route::get('/contributions', [\App\Http\Controllers\Deacon\ContributionsController::class, 'index']);
        Route::post('/contributions', [\App\Http\Controllers\Deacon\ContributionsController::class, 'store']);
        Route::get('/contributions/{contribution}', [\App\Http\Controllers\Deacon\ContributionsController::class, 'show']);
        Route::get('/contributions-statistics', [\App\Http\Controllers\Deacon\ContributionsController::class, 'statistics']);
    });
});

// Secretary routes
Route::middleware(['auth:sanctum', 'role:secretary'])->group(function(){
    Route::prefix('secretary')->group(function(){
        Route::get('/me', [\App\Http\Controllers\Secretary\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Secretary\AuthController::class, 'logout']);
        
        Route::get('/members', [\App\Http\Controllers\Secretary\MembersController::class, 'index']);
        Route::post('/members', [\App\Http\Controllers\Secretary\MembersController::class, 'store']);
        Route::get('/members/{member}', [\App\Http\Controllers\Secretary\MembersController::class, 'show']);
        Route::put('/members/{member}', [\App\Http\Controllers\Secretary\MembersController::class, 'update']);
    });
});

// Minutes routes
Route::middleware('auth:sanctum')->group(function(){
    Route::post('/minutes', [\App\Http\Controllers\MinutesController::class, 'store']);
    Route::get('/minutes/mine', [\App\Http\Controllers\MinutesController::class, 'mine']);
});

// Treasurer routes
Route::middleware(['auth:sanctum', 'role:treasurer'])->group(function(){
    Route::prefix('treasurer')->group(function(){
        Route::get('/me', [\App\Http\Controllers\Treasurer\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Treasurer\AuthController::class, 'logout']);
        
        Route::get('/financial-overview', [\App\Http\Controllers\Treasurer\FinancialController::class, 'overview']);
        Route::get('/financial-reports', [\App\Http\Controllers\Treasurer\FinancialController::class, 'reports']);
        Route::get('/transactions', [\App\Http\Controllers\Treasurer\FinancialController::class, 'transactions']);
    });
});

// Choir Leader routes
Route::middleware(['auth:sanctum', 'role:choir_leader'])->group(function(){
    Route::prefix('choir-leader')->group(function(){
        Route::get('/me', [\App\Http\Controllers\ChoirLeader\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\ChoirLeader\AuthController::class, 'logout']);
        
        Route::get('/choir-members', [\App\Http\Controllers\ChoirLeader\ChoirController::class, 'members']);
        Route::post('/add-member', [\App\Http\Controllers\ChoirLeader\ChoirController::class, 'addMember']);
        Route::delete('/remove-member/{member}', [\App\Http\Controllers\ChoirLeader\ChoirController::class, 'removeMember']);
        Route::get('/events', [\App\Http\Controllers\ChoirLeader\ChoirController::class, 'events']);
    });
});

// Youth Leader routes
Route::middleware(['auth:sanctum', 'role:youth_leader'])->group(function(){
    Route::prefix('youth-leader')->group(function(){
        Route::get('/me', [\App\Http\Controllers\YouthLeader\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\YouthLeader\AuthController::class, 'logout']);
        
        Route::get('/youth-members', [\App\Http\Controllers\YouthLeader\YouthController::class, 'members']);
        Route::post('/add-member', [\App\Http\Controllers\YouthLeader\YouthController::class, 'addMember']);
        Route::get('/events', [\App\Http\Controllers\YouthLeader\YouthController::class, 'events']);
        Route::post('/create-event', [\App\Http\Controllers\YouthLeader\YouthController::class, 'createEvent']);
        Route::get('/statistics', [\App\Http\Controllers\YouthLeader\YouthController::class, 'statistics']);
        
        // Group management routes
        Route::get('/assigned-group', [\App\Http\Controllers\YouthLeader\GroupsController::class, 'getAssignedGroup']);
        Route::get('/group-members', [\App\Http\Controllers\YouthLeader\GroupsController::class, 'getGroupMembers']);
        Route::post('/broadcast-message', [\App\Http\Controllers\YouthLeader\GroupsController::class, 'broadcastMessage']);
        Route::post('/send-message', [\App\Http\Controllers\YouthLeader\GroupsController::class, 'sendIndividualMessage']);
    });
});

// Chairman routes
Route::middleware(['auth:sanctum', 'role:chairman'])->group(function(){
    Route::prefix('chairman')->group(function(){
        Route::get('/me', [\App\Http\Controllers\Chairman\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Chairman\AuthController::class, 'logout']);
        
        Route::get('/members', [\App\Http\Controllers\Chairman\MembersController::class, 'index']);
        Route::get('/members/{member}', [\App\Http\Controllers\Chairman\MembersController::class, 'show']);
        Route::put('/members/{member}', [\App\Http\Controllers\Chairman\MembersController::class, 'update']);
        
        Route::get('/contributions', [\App\Http\Controllers\Chairman\ContributionsController::class, 'index']);
        Route::post('/contributions', [\App\Http\Controllers\Chairman\ContributionsController::class, 'store']);
        Route::get('/contributions/{contribution}', [\App\Http\Controllers\Chairman\ContributionsController::class, 'show']);
        Route::get('/contributions-statistics', [\App\Http\Controllers\Chairman\ContributionsController::class, 'statistics']);
        
        Route::get('/leadership-dashboard', [\App\Http\Controllers\Chairman\DashboardController::class, 'index']);
    });
});

// Sunday School Teacher routes
Route::middleware(['auth:sanctum', 'role:sunday_school_teacher'])->group(function(){
    Route::prefix('sunday-school-teacher')->group(function(){
        Route::get('/me', [\App\Http\Controllers\SundaySchoolTeacher\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\SundaySchoolTeacher\AuthController::class, 'logout']);
        
        Route::get('/students', [\App\Http\Controllers\SundaySchoolTeacher\StudentsController::class, 'index']);
        Route::get('/students/{student}', [\App\Http\Controllers\SundaySchoolTeacher\StudentsController::class, 'show']);
        Route::post('/students', [\App\Http\Controllers\SundaySchoolTeacher\StudentsController::class, 'store']);
        Route::put('/students/{student}', [\App\Http\Controllers\SundaySchoolTeacher\StudentsController::class, 'update']);
        
        Route::get('/events', [\App\Http\Controllers\SundaySchoolTeacher\EventsController::class, 'index']);
        Route::post('/events', [\App\Http\Controllers\SundaySchoolTeacher\EventsController::class, 'store']);
        Route::get('/events/{event}', [\App\Http\Controllers\SundaySchoolTeacher\EventsController::class, 'show']);
        Route::put('/events/{event}', [\App\Http\Controllers\SundaySchoolTeacher\EventsController::class, 'update']);
        Route::delete('/events/{event}', [\App\Http\Controllers\SundaySchoolTeacher\EventsController::class, 'destroy']);
        
        Route::get('/curriculum', [\App\Http\Controllers\SundaySchoolTeacher\CurriculumController::class, 'index']);
        Route::post('/curriculum', [\App\Http\Controllers\SundaySchoolTeacher\CurriculumController::class, 'store']);
        Route::get('/curriculum/{curriculum}', [\App\Http\Controllers\SundaySchoolTeacher\CurriculumController::class, 'show']);
        Route::put('/curriculum/{curriculum}', [\App\Http\Controllers\SundaySchoolTeacher\CurriculumController::class, 'update']);
    });
});

// Member routes (for regular church members)
Route::middleware(['auth:sanctum'])->group(function(){
    Route::prefix('member')->group(function(){
        Route::get('/me', [\App\Http\Controllers\Member\AuthController::class, 'me']);
        Route::post('/logout', [\App\Http\Controllers\Member\AuthController::class, 'logout']);
        
        // Profile management
        Route::get('/profile', [\App\Http\Controllers\Member\ProfileController::class, 'show']);
        Route::put('/profile', [\App\Http\Controllers\Member\ProfileController::class, 'update']);
        Route::post('/profile/avatar', [\App\Http\Controllers\Member\ProfileController::class, 'updateAvatar']);
        Route::post('/profile/passport', [\App\Http\Controllers\Member\ProfileController::class, 'updatePassport']);
        
        // Contributions
        Route::get('/contributions', [\App\Http\Controllers\Member\ContributionsController::class, 'index']);
        Route::get('/contributions/{contribution}', [\App\Http\Controllers\Member\ContributionsController::class, 'show']);
        Route::get('/contributions-statistics', [\App\Http\Controllers\Member\ContributionsController::class, 'statistics']);
        
        // Pledges
        Route::get('/pledges', [\App\Http\Controllers\PledgeController::class, 'index']);
        Route::post('/pledges', [\App\Http\Controllers\PledgeController::class, 'store']);
        Route::get('/pledges/{id}', [\App\Http\Controllers\PledgeController::class, 'show']);
        Route::put('/pledges/{id}', [\App\Http\Controllers\PledgeController::class, 'update']);
        Route::delete('/pledges/{id}', [\App\Http\Controllers\PledgeController::class, 'destroy']);
        
        // Dependents
        Route::get('/dependents', [\App\Http\Controllers\Member\DependentsController::class, 'index']);
        Route::post('/dependents', [\App\Http\Controllers\Member\DependentsController::class, 'store']);
        Route::put('/dependents/{dependency}', [\App\Http\Controllers\Member\DependentsController::class, 'update']);
        Route::delete('/dependents/{dependency}', [\App\Http\Controllers\Member\DependentsController::class, 'destroy']);
        Route::post('/dependents/{dependency}/image', [\App\Http\Controllers\Member\DependentsController::class, 'updateImage']);
        
        // Dashboard
        Route::get('/dashboard', [\App\Http\Controllers\Member\DashboardController::class, 'index']);
        Route::get('/notifications', [\App\Http\Controllers\Member\DashboardController::class, 'notifications']);
        Route::post('/notifications/{announcement}/reply', [\App\Http\Controllers\Member\DashboardController::class, 'reply']);
        Route::delete('/notifications/{announcement}', [\App\Http\Controllers\Member\DashboardController::class, 'delete']);
        Route::post('/notifications/{announcement}/mark-read', [\App\Http\Controllers\Member\DashboardController::class, 'markAsRead']);
        Route::get('/notifications/unread-count', [\App\Http\Controllers\Member\DashboardController::class, 'unreadCount']);
        Route::get('/events', [\App\Http\Controllers\Member\EventsController::class, 'index']);
        Route::get('/events/{event}', [\App\Http\Controllers\Member\EventsController::class, 'show']);
        // Messages to elders
        Route::get('/elders', [\App\Http\Controllers\Member\DashboardController::class, 'getElders']);
        Route::post('/send-message-to-elder', [\App\Http\Controllers\Member\DashboardController::class, 'sendMessageToElder']);
        Route::get('/sent-messages', [\App\Http\Controllers\Member\DashboardController::class, 'sentMessages']);
    });
});
