<?php

namespace App\Repositories\sql;

use App\Repositories\Interface\CountryRepositoryInterface;
use Illuminate\Support\Facades\DB;

class CountryRepository implements CountryRepositoryInterface
{
    public function getAll(): array
    {
        return DB::select('SELECT CountryID ,Name FROM Countries');
    }
    public function isExistsByID(int $countryID): bool
{
    $result = DB::select('SELECT 1 FROM Countries WHERE CountryID = ? LIMIT 1', [$countryID]);
    return !empty($result);
}
}