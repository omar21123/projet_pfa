<?php

namespace App\Http\Controllers;

use Exception;
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
    #[OA\Response(
        response: 500,
        description: "Internal Server Error"
    )]
    public function ping()
    {
        try {
            return response()->json([
                'message' => 'Swagger fonctionne !'
            ], 200);
        } catch (Exception $ex) {
            return response()->json([
                'success' => false,
                'message' => $ex->getMessage(),
                'exception' => get_class($ex),
                'file' => $ex->getFile(),
                'line' => $ex->getLine(),
                'trace' => $ex->getTraceAsString(),
            ], 500);
        }
    }
}