<?php

namespace App\DTOs\Search;

class GetSearchHistoryDto
{
    public function __construct(
        public readonly string $userPublicId,
        public readonly string $ipAddress,
        public readonly int $latestLimit,
        public readonly int $famousLimit,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            userPublicId: $data['UserPublicID'],
            ipAddress: $data['IPAddress'],
            latestLimit: (int) ($data['LatestLimit'] ?? 10),
            famousLimit: (int) ($data['FamousLimit'] ?? 10),
        );
    }
}