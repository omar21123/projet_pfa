<?php

namespace App\Http\Controllers;

use OpenApi\Attributes as OA;

class TestController extends Controller
{
    #[OA\Get(
        path: "/api/test",
        tags: ["Test"],
        summary: "Route de test pour vérifier Swagger"
    )]
    #[OA\Response(
        response: 200,
        description: "Ça fonctionne"
    )]
    public function ping()
    {
        return response()->json([
            'message' => 'Swagger fonctionne !'
        ]);
    }
}