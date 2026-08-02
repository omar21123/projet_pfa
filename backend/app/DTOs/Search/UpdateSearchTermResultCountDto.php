<?php
// App\DTOs\Search\UpdateSearchTermResultCountDto
namespace App\DTOs\Search;

class UpdateSearchTermResultCountDto
{
    public function __construct(
        public readonly int $searchTermId,
        public readonly int $resultCount,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            searchTermId: $data['searchTermId'],
            resultCount: $data['resultCount'],
        );
    }
}