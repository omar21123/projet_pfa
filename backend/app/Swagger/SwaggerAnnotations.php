<?php

/**
 * Minimal OpenAPI annotations to satisfy swagger-php scanning.
 *
 * @OA\Info(
 *     title="API",
 *     version="1.0.0"
 * )
 *
 * @OA\Get(
 *     path="/health",
 *     summary="Health check",
 *     @OA\Response(
 *         response=200,
 *         description="OK"
 *     )
 * )
 */

// This file intentionally has no runtime code; it's only for annotations.
