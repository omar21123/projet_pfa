<?php

namespace App\Repositories\sql;

use App\DTOs\Tag\CreateTagDto;
use App\DTOs\Tag\UpdateTagDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\TagRepositoryInterface;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class TagRepository implements TagRepositoryInterface
{
    public function create(CreateTagDto $dto): ?object
    {
        try {
            $result = DB::select('CALL SP_CreateTag(?, ?, ?)', [
                $dto->name,
                $dto->color,
                $dto->description,
            ]);
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $result[0] ?? null;
    }

    /**
     * MySQL raises error code 1062 (SQLSTATE 23000) for a unique
     * constraint violation on Tags.Name.
     */
    private function translateSqlException(QueryException $e): BusinessValidationException|QueryException
    {
        $sqlState  = $e->errorInfo[0] ?? null;
        $errorCode = $e->errorInfo[1] ?? null;

        if ($sqlState === '23000' && $errorCode === 1062) {
            return new BusinessValidationException(
                'Un tag avec ce nom existe déjà.',
                422

            );
        }

        return $e;
    }

    public function existsById(int $id): bool
    {
        $result = DB::select("
            SELECT EXISTS(
                SELECT 1 FROM Tags WHERE TagID = ?
            ) AS `exists`
        ", [$id]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function existsByName(string $name): bool
    {
        $result = DB::select("
            SELECT EXISTS(
                SELECT 1 FROM Tags WHERE Name = ?
            ) AS `exists`
        ", [$name]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function findById(int $id): ?object
    {
        $tag = DB::select("
            SELECT *
            FROM Tags
            WHERE TagID = ?
        ", [$id]);

        return $tag[0] ?? null;
    }

    public function update(int $id, UpdateTagDto $dto): bool
    {
        try {
            $updated = DB::update("
                UPDATE Tags
                SET
                    Name = ?,
                    Color = ?,
                    Description = ?,
                    IsActive = ?
                WHERE TagID = ?
            ", [
                $dto->name,
                $dto->color,
                $dto->description,
                $dto->isActive ? 1 : 0,
                $id
            ]);
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $updated > 0;
    }

    public function updateStatus(int $id, bool $isActive): bool
    {
        return DB::update("
            UPDATE Tags
            SET IsActive = ?
            WHERE TagID = ?
        ", [
            $isActive ? 1 : 0,
            $id
        ]) > 0;
    }

    public function delete(int $id): bool
    {
        return DB::delete("
            DELETE FROM Tags
            WHERE TagID = ?
        ", [$id]) > 0;
    }

    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['1=1'];
        $bindings = [];

        if (!empty($filters['search'])) {
            $where[] = '(Name LIKE ? OR Description LIKE ?)';
            $searchTerm = '%' . $filters['search'] . '%';
            $bindings[] = $searchTerm;
            $bindings[] = $searchTerm;
        }

        if (isset($filters['isActive'])) {
            $where[] = 'IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'Name');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';

        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate
            FROM Tags
            WHERE {$whereSql} And IsActive = 1
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT *
            FROM Tags
            WHERE {$whereSql} And IsActive = 1
            ORDER BY {$sortColumn} {$sortDir}
            LIMIT {$perPage} OFFSET {$offset}
        ", $bindings);

        return [
            'data' => $rows,
            'total' => (int) $total,
            'page' => $page,
            'perPage' => $perPage,
            'lastPage' => (int) ceil($total / $perPage),
        ];
    }
    public function createByName(string $name): int
    {
        try {
            DB::select('CALL SP_CreateTagByName(?, @tagId)', [$name]);
            $result = DB::select('SELECT @tagId AS TagID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return (int) $result[0]->TagID;
    }

    /**
     * Whitelist sortable columns to prevent SQL injection via sortBy —
     * never interpolate a client-supplied column name directly.
     */
    private function resolveSortColumn(string $sortBy): string
    {
        return match ($sortBy) {
            'CreatedAt' => 'CreatedAt',
            'IsActive'  => 'IsActive',
            default     => 'Name',
        };
    }
}
