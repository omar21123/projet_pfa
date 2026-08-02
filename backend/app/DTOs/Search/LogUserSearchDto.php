<?php
// App\DTOs\Search\LogUserSearchDto
namespace App\DTOs\Search;

class LogUserSearchDto
{
    public function __construct(
        public readonly ?string $userPublicId,
        public readonly int $searchTermId,
        public readonly ?string $ipAddress,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['userPublicId'] ?? null,
            searchTermId: $data['searchTermId'],
            ipAddress: $data['ipAddress'] ?? null,
        );
    }
}