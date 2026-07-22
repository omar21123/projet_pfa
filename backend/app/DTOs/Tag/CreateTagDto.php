<?php

namespace App\DTOs\Tag;

use Illuminate\Http\Request;

class CreateTagDto
{
    public function __construct(
        public readonly string $name,
        public readonly ?string $color = null,
        public readonly ?string $description = null,
    ) {}

    public static function fromRequest(Request $request): self
    {
        return new self(
            name: $request->input('Name'),
            color: $request->input('Color'),
            description: $request->input('Description'),
        );
    }
}