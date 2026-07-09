<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TestController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CountryController;


Route::middleware(['jwt.custom' , 'role:CUSTOMER'])->group(function () {

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


Route::get('/countries', [CountryController::class, 'index']);