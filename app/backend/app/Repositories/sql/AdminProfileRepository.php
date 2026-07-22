<?php

namespace App\Repositories\sql;

use App\DTOs\Admin\AdminProfileDto;
use App\Repositories\Interface\AdminProfileRepositoryInterface;
use Illuminate\Support\Facades\DB;

/**
 * ⚠️ SQL brut — pas d'Eloquent. Tables et colonnes en PascalCase
 * pour correspondre exactement à ton schéma de base de données.
 */
class AdminProfileRepository implements AdminProfileRepositoryInterface
{
    public function findAdminProfileByPublicId(string $publicId): ?AdminProfileDto
    {
        $sql = "
            SELECT 
                u.PublicID, 
                u.FirstName, 
                u.LastName, 
                u.DisplayName, 
                u.Email, 
                u.PhoneNumber, 
                u.AvatarURL, 
                u.LastLoginAt,
                ap.EmployeeNumber, 
                ap.CIN, 
                ap.Position, 
                ap.Status, 
                ap.IdentityVerified, 
                ap.HireDate
            FROM Users u
            INNER JOIN AdminProfiles ap ON u.UserID = ap.UserID
            WHERE u.PublicID = ? 
              AND u.IsActive = 1 
              AND u.IsDeleted = 0
        ";

        $row = DB::selectOne($sql, [$publicId]);

        return $row ? AdminProfileDto::fromDbRow($row) : null;
    }
}