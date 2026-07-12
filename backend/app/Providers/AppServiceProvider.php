<?php

namespace App\Providers;

use App\Repositories\Interface\CategoryRepositoryInterface;
use App\Repositories\Interface\UserRepositoryInterface;
use App\Repositories\sql\CategoryRepository;
use App\Repositories\sql\UserRepository;
use App\Services\Interface\CategoryServiceInterface;
use App\Repositories\Interface\AdminRepositoryInterface; // 💡 Ajouté

use App\Repositories\Interface\RefreshTokenRepositoryInterface;
use App\Repositories\sql\RefreshTokenRepository;
use App\Repositories\sql\AdminRepository;
use App\Services\AuthService;
use App\Services\Interface\AuthServiceInterface;
use App\Services\Interface\AdminServiceInterface; // 💡 Ajouté
use App\Services\CategoryService;
use App\Services\AccessTokenService;
use App\Services\AdminService;
use App\Services\RefreshTokenService;
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
        $this->app->singleton(AccessTokenService::class, function () {
            return new AccessTokenService(
                secret: config('jwt.secret'),
                ttl: config('jwt.access_ttl'),
            );
        });

        $this->app->singleton(RefreshTokenService::class, function () {
            return new RefreshTokenService(
                ttl: config('jwt.refresh_ttl'),
            );
        });

        $this->app->bind(AuthServiceInterface::class, AuthService::class);
        $this->app->bind(CategoryRepositoryInterface::class, CategoryRepository::class);
        $this->app->bind(CategoryServiceInterface::class, CategoryService::class);
        $this->app->bind(UserRepositoryInterface::class, UserRepository::class);
        $this->app->bind(RefreshTokenRepositoryInterface::class, RefreshTokenRepository::class);
        $this->app->bind(
            \App\Repositories\Interface\CountryRepositoryInterface::class,
            \App\Repositories\sql\CountryRepository::class
        );

        $this->app->bind(
            \App\Services\Interface\CountryServiceInterface::class,
            \App\Services\CountryService::class
        );
        $this->app->bind(
            \App\Services\Interface\UserServiceInterface::class,
            \App\Services\UserService::class
        );
        $this->app->bind(AdminRepositoryInterface::class, AdminRepository::class);
$this->app->bind(
    AdminServiceInterface::class,
    AdminService::class
);    
$this->app->bind(
        \App\Services\Interface\FileUploadServiceInterface::class,
        \App\Services\FileUploadService::class
    );


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
        // AppServiceProvider::boot()

        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });
    }
}