<?php

namespace App\DTOs\ProductResource;

class CreateProductResourceDto
{
    public function __construct(
        public readonly string $type,
        public readonly int $role,
        public readonly string $path,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            type: $data['type'],
            role: (int) $data['Role'],
            path: $data['Path'],
        );
    }
}