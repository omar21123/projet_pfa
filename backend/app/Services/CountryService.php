<?php

namespace App\Services;

use App\DTOs\Country\CountryDto;
use App\Repositories\Interface\CountryRepositoryInterface;
use App\Services\Interface\CountryServiceInterface;

class CountryService implements CountryServiceInterface
{
    public function __construct(
        private readonly CountryRepositoryInterface $countryRepository
    ) {}

    public function getAllCountries(): array
    {
        $rows = $this->countryRepository->getAll();

        return array_map(
            fn ($row) => CountryDto::fromRow($row)->toArray(),
            $rows
        );
    }
     public function isExistsByID(int $countryID): bool {
        return $this->countryRepository->isExistsByID($countryID);
     }
}