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
        try {
            $result = DB::select('CALL SP_CreateCategory(?, ?, ?)', [
                $dto->parentCategoryID,
                $dto->name,
                $dto->iconURL,
            ]);
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $result[0] ?? null;
    }

    /**
     * SP_CreateCategory uses SIGNAL SQLSTATE '45000' for both the
     * "parent doesn't exist" and "duplicate slug" checks. errorInfo[2]
     * carries the MESSAGE_TEXT set in the SIGNAL statement.
     */
    private function translateSqlException(QueryException $e): \Throwable
    {
        $sqlState = $e->errorInfo[0] ?? null;

        if ($sqlState === '45000') {
            $message = $e->errorInfo[2] ?? 'Une erreur est survenue lors de la création de la catégorie.';
            return new BusinessValidationException($message, 422, $e);
        }

        return $e;
    }
public function existsById(int $id): bool
{
    $result = DB::select("
        SELECT EXISTS(
            SELECT 1 FROM Categories WHERE CategoryID = ?
        ) AS `exists`
    ", [$id]);

    return (bool) ($result[0]->exists ?? false);
}
public function existsByName(string $name): bool
{
    $result = DB::select("
        SELECT EXISTS(
            SELECT 1 FROM Categories WHERE Name = ?
        ) AS `exists`
    ", [$name]);
    return (bool) ($result[0]->exists ?? false);
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