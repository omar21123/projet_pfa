<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
    'http://localhost',
    'http://127.0.0.1:8000',
    'http://localhost:8000',
    'http://localhost:8080',
],
'supports_credentials' => true,
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'], // Permet de laisser passer l'en-tête Authorization
    'exposed_headers' => ['Authorization'],
    'max_age' => 0,
    'supports_credentials' => true, 
];