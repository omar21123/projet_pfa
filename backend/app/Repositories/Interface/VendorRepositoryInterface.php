<?php

namespace App\Repositories\Interface;

interface VendorRepositoryInterface
{
    public function findByUserId(int $userId): ?object;
}