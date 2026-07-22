<?php

return [
    'secret'      => env('JWT_SECRET'),
    'access_ttl'  => env('JWT_ACCESS_TTL', 900),        // 15 minutes
    'refresh_ttl' => env('JWT_REFRESH_TTL', 2592000),   // 30 days
];