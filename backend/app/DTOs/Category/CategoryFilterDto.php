<?php
namespace App\DTOs\Category;

class CategoryFilterDto
{
    public function __construct(
        public ?string $search = null,
        public ?bool $isActive = null,
        public bool $hasProducts = false,
        public bool $isEmpty = false,
        public string $sortBy = 'DisplayOrder',
        public string $sortDir = 'asc',
        public int $page = 1,
        public int $perPage = 20,
    ) {
    }

    public static function fromRequest($request): self
    {
        return new self(
            search: $request->query('search'),
            isActive: $request->has('isActive') ? (bool) $request->query('isActive') : null,
            hasProducts: (bool) $request->query('hasProducts', false),
            isEmpty: (bool) $request->query('isEmpty', false),
            sortBy: $request->query('sortBy', 'DisplayOrder'),
            sortDir: $request->query('sortDir', 'asc'),
            page: (int) $request->query('page', 1),
            perPage: min((int) $request->query('perPage', 20), 100), // cap to prevent abuse
        );
    }

    public function toArray(): array
    {
        return [
            'search' => $this->search,
            'isActive' => $this->isActive,
            'hasProducts' => $this->hasProducts,
            'isEmpty' => $this->isEmpty,
            'sortBy' => $this->sortBy,
            'sortDir' => $this->sortDir,
        ];
    }
}