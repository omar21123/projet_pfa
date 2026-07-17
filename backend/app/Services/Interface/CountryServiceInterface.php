<?php

namespace App\Services\Interface;

interface CountryServiceInterface
{
    public function getAllCountries(): array;
    public function isExistsByID(int $countryID): bool;
}