<?php

namespace App\Providers;

use App\Repositories\Interface\CategoryRepositoryInterface;
use App\Repositories\Interface\UserRepositoryInterface;
use App\Repositories\sql\CategoryRepository;
use App\Repositories\sql\UserRepository;
use App\Services\Interface\CategoryServiceInterface;
use App\Repositories\Interface\AdminRepositoryInterface;

use App\Repositories\Interface\RefreshTokenRepositoryInterface;
use App\Repositories\sql\RefreshTokenRepository;
use App\Repositories\sql\AdminRepository;
use App\Services\AuthService;
use App\Services\Interface\AuthServiceInterface;
use App\Services\Interface\AdminServiceInterface;
use App\Services\CategoryService;
use App\Services\AccessTokenService;
use App\Services\AdminService;
use App\Services\RefreshTokenService;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;

// 💡 AJOUT DES IMPORTS POUR LE PROFIL ADMIN (Repository + Service)
use App\Repositories\Interface\AdminProfileRepositoryInterface;
use App\Repositories\sql\AdminProfileRepository;
use App\Services\Interface\AdminProfileServiceInterface;
use App\Services\AdminProfileService;

// 🏷️ AJOUT DES IMPORTS POUR LES TAGS (Repository + Service)
use App\Repositories\Interface\TagRepositoryInterface;
use App\Repositories\sql\TagRepository;
use App\Services\Interface\TagServiceInterface;
use App\Services\TagService;

// 🏭 AJOUT DES IMPORTS POUR LES BRANDS (Repository + Service)
use App\Repositories\Interface\BrandRepositoryInterface;
use App\Repositories\sql\BrandRepository;
use App\Services\Interface\BrandServiceInterface;
use App\Services\BrandService;
// ==========================================================
// 🚘 AJOUT : Liaisons pour la gestion des Models (ProductModel)
// ==========================================================
use App\Repositories\Interface\ProductModelRepositoryInterface;
use App\Repositories\sql\ProductModelRepository;
use App\Services\Interface\ProductModelServiceInterface;
use App\Services\ProductModelService;
// ==========================================================
// 📏 AJOUT : Liaisons pour la gestion des Units
// ==========================================================
use App\Repositories\Interface\UnitRepositoryInterface;
use App\Repositories\sql\UnitRepository;
use App\Services\Interface\UnitServiceInterface;
use App\Services\UnitService;
// ==========================================================
// 🧩 AJOUT : Liaisons pour la gestion des ProductsConfigAttribute
// ==========================================================
use App\Repositories\Interface\ProductsConfigAttributeRepositoryInterface;
use App\Repositories\sql\ProductsConfigAttributeRepository;
use App\Services\Interface\ProductsConfigAttributeServiceInterface;
use App\Services\ProductsConfigAttributeService;
use App\Repositories\Interface\ConfigAttributeOptionRepositoryInterface;
use App\Repositories\sql\ConfigAttributeOptionRepository;
use App\Services\Interface\ConfigAttributeOptionServiceInterface;
use App\Services\ConfigAttributeOptionService;

use App\Repositories\Interface\ProductRepositoryInterface;
use App\Repositories\sql\ProductRepository;
use App\Services\Interface\ProductServiceInterface;
use App\Services\ProductService;

use App\Repositories\Interface\VendorRepositoryInterface;
use App\Repositories\sql\VendorRepository;
use App\Services\Interface\VendorServiceInterface;
use App\Services\VendorService;

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

        $this->app->bind(
            \App\Repositories\Interface\AdminVendorRepositoryInterface::class,
            \App\Repositories\sql\AdminVendorRepository::class
        );

        $this->app->bind(
            \App\Services\Interface\AdminVendorServiceInterface::class,
            \App\Services\AdminVendorService::class
        );

        // ==========================================================
        // 🚀 AJOUT : Liaisons pour la gestion du Profil Admin
        // ==========================================================
        $this->app->bind(
            AdminProfileRepositoryInterface::class,
            AdminProfileRepository::class
        );

        $this->app->bind(
            AdminProfileServiceInterface::class,
            AdminProfileService::class
        );

        // ==========================================================
        // 🏷️ AJOUT : Liaisons pour la gestion des Tags
        // ==========================================================
        $this->app->bind(
            TagRepositoryInterface::class,
            TagRepository::class
        );

        $this->app->bind(
            TagServiceInterface::class,
            TagService::class
        );

        // ==========================================================
        // 🏭 AJOUT : Liaisons pour la gestion des Brands
        // ==========================================================
        $this->app->bind(
            BrandRepositoryInterface::class,
            BrandRepository::class
        );

        $this->app->bind(
            BrandServiceInterface::class,
            BrandService::class
        );
        $this->app->bind(
            ProductModelRepositoryInterface::class,
            ProductModelRepository::class
        );

        $this->app->bind(
            ProductModelServiceInterface::class,
            ProductModelService::class
        );
        $this->app->bind(
            UnitRepositoryInterface::class,
            UnitRepository::class
        );

        $this->app->bind(
            UnitServiceInterface::class,
            UnitService::class
        );
        // ==========================================================
        // 🧩 AJOUT : Liaisons pour la gestion des ProductsConfigAttribute
        // ==========================================================
        $this->app->bind(
            ProductsConfigAttributeRepositoryInterface::class,
            ProductsConfigAttributeRepository::class
        );

        $this->app->bind(
            ProductsConfigAttributeServiceInterface::class,
            ProductsConfigAttributeService::class
        );
        $this->app->bind(
            ConfigAttributeOptionRepositoryInterface::class,
            ConfigAttributeOptionRepository::class
        );

        $this->app->bind(
            ConfigAttributeOptionServiceInterface::class,
            ConfigAttributeOptionService::class
        );
        // ==========================================================
        // 📦 AJOUT : Liaisons pour la gestion des Products
        // ==========================================================
        $this->app->bind(
            ProductRepositoryInterface::class,
            ProductRepository::class
        );

        $this->app->bind(
            ProductServiceInterface::class,
            ProductService::class
        );
        $this->app->bind(
            VendorRepositoryInterface::class,
            VendorRepository::class
        );

        $this->app->bind(
            VendorServiceInterface::class,
            VendorService::class
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

        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });
    }
}
