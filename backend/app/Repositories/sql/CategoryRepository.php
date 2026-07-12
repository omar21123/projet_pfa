<?php

namespace App\Repositories\sql;

use App\DTOs\Category\CreateCategoryDto;
use App\DTOs\Category\UpdateCategoryDto;
use App\Repositories\Interface\CategoryRepositoryInterface;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CategoryRepository implements CategoryRepositoryInterface
{
    public function create(CreateCategoryDto $dto): ?object
    {
        return DB::transaction(function () use ($dto) {

            $slug = Str::slug($dto->name) . '-' . uniqid();

            DB::insert("
                INSERT INTO Categories
                (
                    Name,
                    Slug,
                    ParentCategoryID,
                    IconURL,
                    IsActive,
                    DisplayOrder,
                    Created_at,
                    Updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ", [
                $dto->name,
                $slug,
                $dto->parentCategoryID,
                $dto->iconURL,
                $dto->isActive ? 1 : 0,
                $dto->displayOrder,
                now(),
                now()
            ]);

            $categoryId = DB::getPdo()->lastInsertId();

            DB::insert("
                INSERT INTO CategoryClosure
                (
                    AncestorID,
                    DescendantID,
                    Depth
                )
                VALUES (?, ?, 0)
            ", [
                $categoryId,
                $categoryId
            ]);

            if ($dto->parentCategoryID) {

                DB::insert("
                    INSERT INTO CategoryClosure
                    (
                        AncestorID,
                        DescendantID,
                        Depth
                    )
                    SELECT
                        AncestorID,
                        ?,
                        Depth + 1
                    FROM CategoryClosure
                    WHERE DescendantID = ?
                ", [
                    $categoryId,
                    $dto->parentCategoryID
                ]);
            }

            $category = DB::select("
                SELECT *
                FROM Categories
                WHERE CategoryID = ?
            ", [$categoryId]);

            return $category[0] ?? null;
        });
    }

    public function getAllTree(): Collection
    {
        return collect(DB::select("
            SELECT *
            FROM Categories
            ORDER BY DisplayOrder
        "));
    }

    public function findById(int $id): ?object
    {
        $category = DB::select("
            SELECT *
            FROM Categories
            WHERE CategoryID = ?
        ", [$id]);

        return $category[0] ?? null;
    }

    public function update(int $id, UpdateCategoryDto $dto): bool
    {
        return DB::transaction(function () use ($id, $dto) {

            $slug = Str::slug($dto->name) . '-' . uniqid();

            $updated = DB::update("
                UPDATE Categories
                SET
                    Name = ?,
                    Slug = ?,
                    IconURL = ?,
                    DisplayOrder = ?,
                    IsActive = ?,
                    updated_at = ?
                WHERE CategoryID = ?
            ", [
                $dto->name,
                $slug,
                $dto->iconURL,
                $dto->displayOrder,
                $dto->isActive ? 1 : 0,
                now(),
                $id
            ]);

            if (!$dto->isActive) {
                $this->propagateInactivation($id);
            }

            return $updated > 0;
        });
    }

    public function updateStatus(int $id, bool $isActive): bool
    {
        return DB::transaction(function () use ($id, $isActive) {

            if (!$isActive) {
                return $this->propagateInactivation($id);
            }

            return DB::update("
                UPDATE Categories
                SET
                    IsActive = 1,
                    updated_at = ?
                WHERE CategoryID = ?
            ", [
                now(),
                $id
            ]) > 0;
        });
    }

    public function delete(int $id): bool
    {
        return DB::delete("
            DELETE FROM Categories
            WHERE CategoryID = ?
        ", [$id]) > 0;
    }

    private function propagateInactivation(int $id): bool
    {
        return DB::update("
            UPDATE Categories
            SET
                IsActive = 0,
                updated_at = ?
            WHERE CategoryID IN
            (
                SELECT DescendantID
                FROM CategoryClosure
                WHERE AncestorID = ?
            )
        ", [
            now(),
            $id
        ]) > 0;
    }
}