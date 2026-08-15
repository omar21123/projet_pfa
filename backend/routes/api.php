<?php

use App\Http\Controllers\AddressController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CountryController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\TagController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\AdminVendorController;
use App\Http\Controllers\admin\AdminProfileController;
use App\Http\Controllers\BrandController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\ProductModelController;
use App\Http\Controllers\UnitController;
use App\Http\Controllers\ProductsConfigAttributeController;
use App\Http\Controllers\ConfigAttributeOptionController;
use App\Http\Controllers\FavoritesController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\GoogleAuthController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductRecommendationController;
use App\Http\Controllers\PromotionController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\StoreRatingController;
use App\Http\Controllers\VendorController;
use App\Http\Controllers\WishlistsController;

Route::prefix('auth')->group(function () {

    // ⚠️ Rate limiting disabled for DEV — re-enable before deploying to prod
    // Route::middleware('throttle:auth')->group(function () {
    Route::post('/mobile/register', [AuthController::class, 'Customerregister']);
    Route::post('/web/customer/register', [AuthController::class, 'CustomerRegisterWeb']);
    Route::post('/mobile/login', [AuthController::class, 'login']);
    Route::post('/web/login', [AuthController::class, 'webLogin']);
    Route::post('/mobile/refresh', [AuthController::class, 'refresh']);
    Route::post('/web/refresh', [AuthController::class, 'webRefresh']);
    Route::post('/mobile/logout', [AuthController::class, 'logout']);
    Route::post('/web/logout', [AuthController::class, 'webLogout']);
    Route::post('/web/vendor/register', [AuthController::class, 'VendorRegisterWeb']);
    Route::post('/mobile/google', [GoogleAuthController::class, 'mobileGoogleLogin']);
    Route::post('/web/google', [GoogleAuthController::class, 'webGoogleLogin']);
    Route::middleware(['jwt.custom'])->group(function () {
        Route::post('/google/complete-profile', [GoogleAuthController::class, 'completeProfile']);
    });    // });

    // TODO — pas encore implémentés
    // Route::post('/set-password', [AuthController::class, 'setPassword']);
});

Route::prefix('categories')->group(function () {
    Route::get('/navbar', [CategoryController::class, 'navbar']);
    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/', [CategoryController::class, 'index']);
        Route::post('/create', [CategoryController::class, 'store']);
        Route::get('/{id}/children', [CategoryController::class, 'children']);
        Route::put('/{id}/deactivate-subtree', [CategoryController::class, 'deactivateSubtree']);
        Route::put('/{id}/activate', [CategoryController::class, 'activate']);
    });
});

Route::prefix('tags')->group(function () {
    Route::get('/', [TagController::class, 'index']);
    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::post('/create', [TagController::class, 'store']);
        Route::post('/create-by-name', [TagController::class, 'storeByName']);
        Route::post('/{id}/disable', [TagController::class, 'disable']);
    });
});
Route::prefix('brands')->group(function () {
    // 🌐 Route Publique
    Route::get('/', [BrandController::class, 'publicIndex']);
    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/admin', [BrandController::class, 'adminIndex']);
        Route::get('/exists', [BrandController::class, 'existsByName']);
        Route::post('/create', [BrandController::class, 'store']);
        Route::post('/{id}', [BrandController::class, 'update']);
        Route::put('/{id}/disable', [BrandController::class, 'disable']);
        Route::put('/{id}/enable', [BrandController::class, 'enable']);
    });
});
Route::prefix('models')->group(function () {
    // 🌐 Route Publique
    Route::get('/', [ProductModelController::class, 'publicIndex']);
    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/admin', [ProductModelController::class, 'adminIndex']);
        Route::post('/create', [ProductModelController::class, 'store']);
        Route::put('/{id}', [ProductModelController::class, 'update']);
        Route::put('/{id}/disable', [ProductModelController::class, 'disable']);
        Route::put('/{id}/enable', [ProductModelController::class, 'enable']);
    });
});

Route::prefix('units')->group(function () {
    // 🌐 Route Publique
    Route::get('/', [UnitController::class, 'publicIndex']);
    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/admin', [UnitController::class, 'adminIndex']);
        Route::post('/create', [UnitController::class, 'store']);
        Route::put('/{id}', [UnitController::class, 'update']);
        Route::put('/{id}/disable', [UnitController::class, 'disable']);
        Route::put('/{id}/enable', [UnitController::class, 'enable']);
    });
});
//for admin
Route::prefix('admin')/*->middleware(['jwt.auth', 'role:admin'])*/->group(function () {
    Route::post('/register', [AdminController::class, 'store']);
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/vendors', [AdminVendorController::class, 'AdminGetAll']);
        Route::post('/vendors/{vendorProfileId}/verify-identity', [AdminVendorController::class, 'AdminVerifyIdentity']);
        Route::post('/vendors/{vendorProfileId}/approve', [AdminVendorController::class, 'AdminApproveVendor']);
        Route::post('/vendors/{vendorProfileId}/reject', [AdminVendorController::class, 'AdminRejectVendor']);
        Route::post('/vendors/{vendorProfileId}/reset-to-pending', [AdminVendorController::class, 'AdminResetVendorToPending']);
    }); // Ajouter un nouvel admin
});

Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
    // Route GET pour récupérer le profil complet de l'administrateur connecté
    Route::get('/admin/profile', [AdminProfileController::class, 'show']);
});

Route::get('/countries', [CountryController::class, 'index']);
Route::prefix('products-config-attributes')->group(function () {
    // 🌐 Route Publique (liste légère : ID + Name)
    Route::get('/', [ProductsConfigAttributeController::class, 'index']);
    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/admin', [ProductsConfigAttributeController::class, 'adminIndex']);
        Route::get('/exists', [ProductsConfigAttributeController::class, 'existsByName']);
        Route::post('/create', [ProductsConfigAttributeController::class, 'store']);
        Route::put('/{id}', [ProductsConfigAttributeController::class, 'update']);
        Route::put('/{id}/disable', [ProductsConfigAttributeController::class, 'disable']);
        Route::put('/{id}/enable', [ProductsConfigAttributeController::class, 'enable']);
    });
});
Route::prefix('config-attribute-options')->group(function () {

    // 🌐 Route Publique (liste légère : ID + Label)
    Route::get('/', [ConfigAttributeOptionController::class, 'index']);

    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/by-attribute/{attributeID}', [ConfigAttributeOptionController::class, 'getAllOptionsByAttributeID']);
        Route::get('/admin', [ConfigAttributeOptionController::class, 'adminIndex']);
        Route::get('/exists', [ConfigAttributeOptionController::class, 'existsByName']);
        Route::post('/create', [ConfigAttributeOptionController::class, 'store']);
        Route::put('/{id}', [ConfigAttributeOptionController::class, 'update']);
        Route::put('/{id}/disable', [ConfigAttributeOptionController::class, 'disable']);
        Route::put('/{id}/enable', [ConfigAttributeOptionController::class, 'enable']);
    });
});
Route::prefix('products')->group(function () {
    Route::post('/info', [ProductController::class, 'getProductInfo']);
    Route::get('/{product}/similar', [ProductController::class, 'getSimilarProducts']);
    Route::get('vendor/{vendorProfileID}', [ProductController::class, 'getVendorPublicProducts']);
    Route::get('/recommendations', [ProductRecommendationController::class, 'index']);
    Route::get('/', [ProductRecommendationController::class, 'index']);
    Route::get('/most-sold/load-more', [ProductRecommendationController::class, 'loadMoreMostSold']);
    Route::get('/most-viewed/load-more', [ProductRecommendationController::class, 'loadMoreMostViewed']);
    Route::get('/most-promoted/load-more', [ProductRecommendationController::class, 'loadMoreMostPromoted']);
    Route::get('/trending/load-more', [ProductRecommendationController::class, 'loadMoreTrending']);
    Route::get('/last-activity/load-more', [ProductRecommendationController::class, 'loadMoreLastActivity']);
    Route::get('/popular-in-region/load-more', [ProductRecommendationController::class, 'loadMorePopularInRegion']);
    Route::get('/new/load-more', [ProductRecommendationController::class, 'loadMoreNew']);
    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:VENDOR,ADMIN'])->group(function () {
        Route::post('/create', [ProductController::class, 'store']);
        Route::get('/{product}/combinations', [ProductController::class, 'getCombinations']);
        Route::get('/combinations/{combination}', [ProductController::class, 'showCombination']);
        Route::put('/combinations/{combination}', [ProductController::class, 'updateCombination']);
    });
    Route::middleware(['jwt.custom', 'role:VENDOR'])->group(function () {
        Route::get('/vendor/me', [ProductController::class, 'getVendorProducts']);
    });

    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::get('/admin', [ProductController::class, 'index']);
        Route::get('/{product}', [ProductController::class, 'show']);
        Route::patch('/{product}/validate', [ProductController::class, 'validateProduct']);
        Route::patch('/{product}/block', [ProductController::class, 'blockProduct']);
        Route::patch('/{product}/refuse', [ProductController::class, 'refuseProduct']);
    });
});

Route::prefix('promotions')->group(function () {
    Route::get('/lookups', [PromotionController::class, 'lookups']);

    Route::middleware(['jwt.custom'])->group(function () {
        Route::put('/{promotion}', [PromotionController::class, 'update']);
    });
    Route::middleware(['jwt.custom', 'role:VENDOR'])->group(function () {
        Route::post('/product', [PromotionController::class, 'createForProduct']);
        Route::delete('/{promotion}', [PromotionController::class, 'destroy']);
        Route::get('/{promotion}', [PromotionController::class, 'show']);
    });
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::post('/category', [PromotionController::class, 'createForCategory']);
        Route::get('/category/{category}', [PromotionController::class, 'getByCategory']);
        Route::get('/', [PromotionController::class, 'index']);
    });
    Route::middleware(['jwt.custom', 'role:ADMIN,VENDOR'])->group(function () {
        Route::patch('/{promotion}/deactivate', [PromotionController::class, 'deactivate']);
        Route::get('/{promotion}', [PromotionController::class, 'show']);
        Route::get('/product/{product}', [PromotionController::class, 'getByProduct']);
    });
});

Route::prefix('search')->group(function () {
    Route::get('/suggestions', [SearchController::class, 'suggestions']);

    Route::middleware(['jwt.custom'])->group(function () {
        Route::get('/history', [SearchController::class, 'history']);
    });
    Route::get('/', [SearchController::class, 'search']);
});

Route::prefix('wishlists')->group(function () {
    Route::middleware(['jwt.custom'])->group(function () {
        Route::get('/', [WishlistsController::class, 'index']);
        Route::post('/', [WishlistsController::class, 'store']);
        Route::post('/{wishListId}/items', [WishlistsController::class, 'addItem']);
        Route::delete('/items/{wishListItemId}', [WishlistsController::class, 'removeItem']);
        Route::delete('/{wishListId}', [WishlistsController::class, 'destroy']);
    });
});
Route::prefix('favorites')->group(function () {
    Route::middleware(['jwt.custom'])->group(function () {
        Route::get('/', [FavoritesController::class, 'index']);
        Route::post('/', [FavoritesController::class, 'store']);
        Route::delete('/{productId}', [FavoritesController::class, 'destroy']);
    });
});

Route::prefix('cart')->group(function () {
    Route::middleware(['jwt.custom'])->group(function () {
        Route::post('/items', [CartController::class, 'addItem']);
        Route::delete('/items', [CartController::class, 'removeItem']);
        Route::get('/', [CartController::class, 'getCart']);
        Route::patch('/items/quantity', [CartController::class, 'updateItemQuantity']);
    });
});

Route::get('/vendors/{vendorProfileID}/public-profile', [VendorController::class, 'publicProfile']);
Route::prefix('vendors/{vendorProfileID}/ratings')->group(function () {
    Route::get('/',    [StoreRatingController::class, 'index']);   // public
    Route::middleware(['jwt.custom'])->group(function () {
        Route::post('/',   [StoreRatingController::class, 'store']);   // auth
        Route::put('/',    [StoreRatingController::class, 'update']);  // auth
        Route::delete('/', [StoreRatingController::class, 'destroy']); // auth
    });
});

Route::get('addresses/shipping/default',             [AddressController::class, 'getDefaultShippingAddress']);

Route::middleware('jwt.custom')->prefix('addresses')->group(function () {
    Route::middleware('role:VENDOR,ADMIN')->get('/orders/{order}/shipping-address', [AddressController::class, 'getOrderShippingAddress']);
    Route::get('/',                          [AddressController::class, 'index']);
    Route::get('/{address}',                 [AddressController::class, 'show']);
    Route::post('/',                         [AddressController::class, 'store']);
    Route::put('/{address}',                 [AddressController::class, 'update']);
    Route::delete('/{address}',              [AddressController::class, 'destroy']);
    Route::patch('/{address}/default-shipping', [AddressController::class, 'setDefaultShipping']);
});
Route::middleware('jwt.custom')->prefix('orders')->group(function () {
  Route::post('/product', [OrderController::class, 'createForProduct']);
});