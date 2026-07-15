<?php

namespace App\Repositories\sql;

use App\DTOs\Admin\CreateAdminDto;
use App\Repositories\Interface\AdminRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminRepository implements AdminRepositoryInterface
{
    public function createAdminUser(
        CreateAdminDto $dto,
        string $passwordHash,
        string $tokenHash,
        ?string $ipAddress,
        int $ttl
    ): string {
        try {

            $result = DB::select(
                'CALL SP_CreateAdminUser(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                    $dto->firstName,
                    $dto->lastName,
                    $dto->birthDate,
                    $dto->gender,
                    $dto->email,
                    $dto->phoneNumber,
                    $dto->cin,
                    $dto->employeeNumber,
                    $dto->position,
                    $passwordHash,
                    $dto->hireDate,
                    $dto->identityVerified ? 1 : 0,
                    $dto->avatarUrl,
                    $tokenHash,
                    $ipAddress,
                    $ttl,
                ]
            );

            return $result[0]->PublicID;

        } catch (\Throwable $e) {

            throw new \Exception(
                'Failed to create admin user. ' . $e->getMessage(),
                0,
                $e
            );
        }
    }
}