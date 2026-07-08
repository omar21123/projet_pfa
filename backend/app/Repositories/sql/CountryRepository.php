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
}