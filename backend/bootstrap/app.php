<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->trustProxies(
            at: '*', // ou l'IP/plage exacte de ton conteneur Nginx si tu veux être strict
            headers: Request::HEADER_X_FORWARDED_FOR |
                Request::HEADER_X_FORWARDED_HOST |
                Request::HEADER_X_FORWARDED_PORT |
                Request::HEADER_X_FORWARDED_PROTO
        );
    })
    ->withMiddleware(function (Middleware $middleware): void {

        // 🔥 ÉTAPE 1 : Activer le middleware CORS global de Laravel
        // (Assure-toi que les requêtes API ne cherchent pas de jeton CSRF web)
        $middleware->validateCsrfTokens(except: [
            'api/*'
        ]);

        $middleware->alias([
            'jwt.custom' => \App\Http\Middleware\JwtAuthMiddleware::class,
            'role' => \App\Http\Middleware\RoleMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // API endpoints must always return JSON, even if the client omits
        // the Accept: application/json header.
        $exceptions->shouldRenderJsonWhen(
            fn(Request $request) => $request->is('api/*') || $request->expectsJson()
        );

        // Give every FormRequest validation failure a consistent API response.
        $exceptions->render(function (ValidationException $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return response()->json([
                'success' => false,
                'message' => 'Incorrect data sent.',
                'errors' => $exception->errors(),
            ], $exception->status);
        });
    })
    ->create();
