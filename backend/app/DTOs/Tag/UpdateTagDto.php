<?php

namespace App\DTOs\Tag;

class UpdateTagDto
{
    public function __construct(
        public readonly string $name,
        public readonly ?string $color = null,
        public readonly ?string $description = null,
        public readonly bool $isActive = true,
    ) {}
}