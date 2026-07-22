<?php

namespace App\DTOs\Admin;

readonly class VendorListFilterDto
{
    public function __construct(
        public ?string $search,
        public ?int $verificationStatus,
        public ?int $isSuspended,
        public int $pageNumber,
        public int $pageSize,
    ) {
    }

    public static function fromArray(array $data): self
    {
        return new self(
            search: $data['search'] ?? null,
            verificationStatus: isset($data['verification_status']) ? (int) $data['verification_status'] : null,
            isSuspended: isset($data['is_suspended']) ? (int) $data['is_suspended'] : null,
            pageNumber: isset($data['page']) ? max(1, (int) $data['page']) : 1,
            pageSize: isset($data['page_size']) ? min(100, max(1, (int) $data['page_size'])) : 20,
        );
    }
}