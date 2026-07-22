<?php

namespace App\DTOs\Auth;

readonly class TokenResponseDto
{
    public function __construct(
        public UserDto $user,
        public string $token,
        public string $tokenType = 'Bearer',
    ) {
    }
}