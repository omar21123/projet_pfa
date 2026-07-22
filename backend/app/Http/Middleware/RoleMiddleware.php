<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RoleMiddleware
{
    /**
     * Usage: ->middleware('role:vendor') or ->middleware('role:vendor,admin')
     */
    public function handle(Request $request, Closure $next, string ...$allowedRoles)
    {
        $role = $request->attributes->get('user_role');

        if ($role === null) {
            // jwt.auth middleware didn't run first, or token had no role claim
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $userRoles = is_array($role) ? $role : [$role];

        if (empty(array_intersect($userRoles, $allowedRoles))) {
            return response()->json(['message' => 'Forbidden — insufficient role'], 403);
        }

        return $next($request);
    }
}