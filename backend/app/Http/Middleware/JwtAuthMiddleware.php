<?php

namespace App\Http\Middleware;

use App\Services\AccessTokenService;
use Closure;
use Illuminate\Http\Request;

class JwtAuthMiddleware
{
    public function __construct(private AccessTokenService $accessTokenService)
    {
    }

    public function handle(Request $request, Closure $next)
    {
        $header = $request->header('Authorization', '');

        if (!str_starts_with($header, 'Bearer ')) {
            return response()->json(['message' => 'Missing or malformed Authorization header'], 401);
        }

        $token = substr($header, 7);

        try {
            $decoded = $this->accessTokenService->verify($token);
        } catch (\DomainException $e) {
            return response()->json(['message' => $e->getMessage()], 401);
        }

        $request->attributes->set('user_id', $decoded->sub);
        $request->attributes->set('user_role', $decoded->role);

        return $next($request);
    }
}