<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TestController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CountryController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\AdminController;



Route::middleware(['jwt.custom', 'role:CUSTOMER'])->group(function () {

    Route::get('/test', [TestController::class, 'ping']);

});


Route::prefix('auth')->group(function () {

    Route::middleware('throttle:auth')->group(function () {
        Route::post('/mobile/register', [AuthController::class, 'Customerregister']);
        Route::post('/web/customer/register', [AuthController::class, 'CustomerRegisterWeb']);
        Route::post('/mobile/login', [AuthController::class, 'login']);
        Route::post('/web/login', [AuthController::class, 'webLogin']);
        Route::post('/mobile/refresh', [AuthController::class, 'refresh']);
        Route::post('/web/refresh', [AuthController::class, 'webRefresh']);
        Route::post('/mobile/logout', [AuthController::class, 'logout']);
        Route::post('/web/logout', [AuthController::class, 'webLogout']);
    });

    // TODO — pas encore implémentés
    // Route::post('/set-password', [AuthController::class, 'setPassword']);

});

Route::prefix('categories')->group(function () {

    // 🔓 Route Publique : Tout le monde peut voir l'arbre des catégories
    Route::get('/', [CategoryController::class, 'index']);
    Route::get('/{id}', [CategoryController::class, 'show']);

    // 🔒 Routes Protégées : Réservées uniquement aux administrateurs connectés
    Route::middleware(['jwt.custom', 'role:ADMIN'])->group(function () {
        Route::post('/', [CategoryController::class, 'store']);
        //Route::put('/{id}', [CategoryController::class, 'update']);
        Route::put('/{id}/status', [CategoryController::class, 'updateStatus']);
        Route::delete('/{id}', [CategoryController::class, 'destroy']);
    });

});
Route::prefix('admin')/*->middleware(['jwt.auth', 'role:admin'])*/ ->group(function () {
    Route::post('/register', [AdminController::class, 'store']); // Ajouter un nouvel admin
});

Route::get('/countries', [CountryController::class, 'index']);
