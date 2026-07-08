<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TestController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CountryController;
Route::middleware('throttle:api')->group(function () {

    Route::get('/test', [TestController::class, 'ping']);

});
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);

    // TODO — pas encore implémentés
    // Route::post('refresh', [AuthController::class, 'refresh']);
    // Route::post('set-password', [AuthController::class, 'setPassword']);
});
Route::get('/countries', [CountryController::class, 'index']);
