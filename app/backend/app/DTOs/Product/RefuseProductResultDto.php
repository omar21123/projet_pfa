<?php

namespace App\DTOs\Product;

class RefuseProductResultDto
{
    public function __construct(
        public readonly string $message,
        public readonly bool $autoBlocked,
    ) {}
}