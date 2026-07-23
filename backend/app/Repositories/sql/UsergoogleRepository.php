<?php

namespace App\Repositories\sql;

use App\DTOs\Auth\LoginInfoDto;
use App\DTOs\Auth\RegisterDto;
use App\DTOs\Auth\UserDto;
use App\DTOs\Auth\UserStandardInfoDto;
use App\DTOs\Auth\VendorRegisterDto;
use App\Repositories\Interface\UsergoogleRepositoryInterface;
use App\Repositories\Interface\UserRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\DTOs\Auth\GoogleUserDto;

class UsergoogleRepository implements UsergoogleRepositoryInterface
{
     public function __construct(
        private UserRepositoryInterface $userRepository,

    ) {}

    public function findByGoogleId(string $googleId): ?UserDto
{
    $row = DB::selectOne(
        "SELECT * FROM Users WHERE google_id = ? AND IsDeleted = 0",
        [$googleId]
    );

    return $row ? UserDto::fromDbRow($row, $this->userRepository->getRolesForUser($row->UserID)) : null;
}

public function linkGoogleAccount(int $userId, string $googleId): void
{
    DB::update(
        "UPDATE Users SET google_id = ?, EmailVerified = 1, UpdatedAt = ? WHERE UserID = ?",
        [$googleId, now()->format('Y-m-d H:i:s'), $userId]
    );
}

// Dans App\Repositories\sql\UsergoogleRepository.php

public function createGoogleCustomer(GoogleUserDto $dto): int
{
    $now = now()->format('Y-m-d H:i:s');
    $publicId = (string) Str::uuid();

    // 1. Suppression de OUTPUT INSERTED.UserID pour MySQL
    $sql = "
        INSERT INTO Users (
            PublicID, FirstName, LastName, DisplayName, Email, google_id,
            AvatarURL, PasswordHash, HasPassword, EmailVerified, PhoneVerified,
            IsActive, IsDeleted, CreatedAt, UpdatedAt
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, NULL, 0, 1, 0, 1, 0, ?, ?)
    ";

    // 2. Utilisation de DB::insert au lieu de DB::select
    DB::insert($sql, [
        $publicId,
        $dto->firstName,
        $dto->lastName ?: $dto->firstName,
        trim($dto->firstName . ' ' . $dto->lastName),
        $dto->email,
        $dto->googleId,
        $dto->avatarUrl,
        $now,
        $now,
    ]);

    // 3. Récupération de l'ID généré via MySQL
    return (int) DB::getPdo()->lastInsertId();
}

}