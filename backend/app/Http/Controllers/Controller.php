<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;
use OpenApi\Attributes as OA;

#[OA\Info(
    title: "Souk API",
    version: "1.0.0",
    description: "API du marketplace"
)]
#[OA\SecurityScheme(
    securityScheme: "sanctum",
    type: "apiKey",
    in: "header",
    name: "Authorization"
)]
class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;

    #[OA\Get(
        path: "/health",
        summary: "Health check",
        responses: [
            new OA\Response(response: 200, description: "OK")
        ]
    )]
    public function swaggerHealth()
    {
        return response()->json(['status' => 'ok']);
    }
}