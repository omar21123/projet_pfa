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
#[OA\Server(
    url: "http://localhost",
    description: "Serveur local"
)]
#[OA\SecurityScheme(
    securityScheme: "bearerAuth",
    type: "http",
    scheme: "bearer",
    bearerFormat: "JWT",
    description: "Entrer uniquement le JWT"
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