<?php

namespace App\DTOs\Cart;

class GetCartDto
{
    public function __construct(
        public readonly string $userPublicId,
    ) {}
}