<?php

namespace App\Repositories\sql;

use App\DTOs\Admin\CreateAdminDto;
use App\Repositories\Interface\AdminRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminRepository implements AdminRepositoryInterface
{
    public function createAdmin(CreateAdminDto $dto): object|null
    {
        return DB::transaction(function () use ($dto) {
            // Insertion de l'utilisateur avec le privilège Admin en SQL Brut
            DB::insert("
                INSERT INTO users (FirstName, LastName, Email, Password, PhoneNumber, Role, IsActive, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
            ", [
                $dto->firstName,
                $dto->lastName,
                $dto->email,
                Hash::make($dto->password), // Chiffrement du mot de passe
                $dto->phoneNumber,
                'admin', // Assigne directement le rôle requis capté par ton middleware
                now(),
                now()
            ]);

            $adminId = DB::getPdo()->lastInsertId();

            $result = DB::select("SELECT UserID, FirstName, LastName, Email, Role FROM users WHERE UserID = ? LIMIT 1", [$adminId]);
            return !empty($result) ? $result[0] : null;
        });
    }
}