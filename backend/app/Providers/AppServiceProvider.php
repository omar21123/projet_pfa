<?php

namespace App\Providers;

use App\Repositories\Interface\UserRepositoryInterface;
use App\Repositories\sql\UserRepository;
use App\Services\AuthService;
use App\Services\Interface\AuthServiceInterface;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(AuthServiceInterface::class, AuthService::class);
        $this->app->bind(UserRepositoryInterface::class, UserRepository::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(2)
                ->by($request->user()?->id ?: $request->ip());
        });
    }
}