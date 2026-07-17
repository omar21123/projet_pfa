<?php

namespace App\Repositories\Interface;

interface CountryRepositoryInterface
{
    public function getAll(): array;
    public function isExistsByID(int $countryID): bool;

}