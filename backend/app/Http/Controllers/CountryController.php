<?php

namespace App\Http\Controllers;

use App\Services\Interface\CountryServiceInterface;
use Exception;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;

class CountryController extends Controller
{
    public function __construct(
        private readonly CountryServiceInterface $countryService
    ) {}

    #[OA\Get(
        path: "/api/countries",
        operationId: "getCountries",
        summary: "Get all countries",
        description: "Returns a list of all available countries.",
        tags: ["Countries"]
    )]
    #[OA\Response(
        response: 200,
        description: "Countries fetched successfully",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "status", type: "integer", example: 200),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(type: "object")
                ),
                new OA\Property(
                    property: "message",
                    type: "string",
                    example: "Countries fetched successfully"
                ),
            ]
        )
    )]
    #[OA\Response(
        response: 500,
        description: "Internal Server Error",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "status", type: "integer", example: 500),
                new OA\Property(property: "data", nullable: true),
                new OA\Property(
                    property: "message",
                    type: "string",
                    example: "Internal Server Error"
                ),
            ]
        )
    )]
    public function index(): JsonResponse
    {
        try {
            $countries = $this->countryService->getAllCountries();

            return response()->json([
                'success' => true,
                'status'  => 200,
                'data'    => $countries,
                'message' => 'Countries fetched successfully',
            ], 200);
        } catch (Exception $ex) {
            return response()->json([
                'success' => false,
                'status'  => 500,
                'data'    => null,
                'message' => $ex->getMessage(),
            ], 500);
        }
    }
}