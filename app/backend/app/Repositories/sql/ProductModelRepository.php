<?php

namespace App\Repositories\sql;

use App\DTOs\ProductModel\CreateProductModelDto;
use App\DTOs\ProductModel\UpdateProductModelDto;
use App\Repositories\Interface\ProductModelRepositoryInterface;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class ProductModelRepository implements ProductModelRepositoryInterface
{
    public function create(CreateProductModelDto $dto): ?object
    {
        try {
            DB::select('CALL SP_CreateModel(?, ?, ?, ?, ?, @modelId)', [
                $dto->brandID,
                $dto->name,
                $dto->code,
                $dto->description,
                $dto->releaseYear,
            ]);
            $result = DB::select('SELECT @modelId AS ModelID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $this->findById((int) $result[0]->ModelID);
    }

    public function createByInfo(int $brandID, string $name): int
    {
        try {
            DB::select('CALL SP_CreateModelByInfo(?, ?, @modelId)', [$brandID, $name]);
            $result = DB::select('SELECT @modelId AS ModelID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return (int) $result[0]->ModelID;
    }

    /**
     * SP_CreateModel / SP_CreateModelByInfo use SIGNAL SQLSTATE '45000'
     * for the "brand doesn't exist" check.
     */
    private function translateSqlException(QueryException $e): \Throwable
    {
        $sqlState = $e->errorInfo[0] ?? null;

        if ($sqlState === '45000') {
            $message = $e->errorInfo[2] ?? 'Une erreur est survenue lors de la création du modèle.';
            return new BusinessValidationException($message, 422, $e);
        }

        return $e;
    }

    public function update(int $id, UpdateProductModelDto $dto): bool
    {
        $updated = DB::update("
            UPDATE Models
            SET
                BrandID = ?,
                Name = ?,
                Code = ?,
                Description = ?,
                ReleaseYear = ?,
                UpdatedAt = ?
            WHERE ModelID = ?
        ", [
            $dto->brandID,
            $dto->name,
            $dto->code,
            $dto->description,
            $dto->releaseYear,
            now(),
            $id
        ]);

        return $updated > 0;
    }

    public function findById(int $id): ?object
    {
        $model = DB::select("
            SELECT m.*, b.Name AS BrandName
            FROM Models m
            JOIN Brands b ON b.BrandID = m.BrandID
            WHERE m.ModelID = ?
        ", [$id]);

        return $model[0] ?? null;
    }

    public function existsById(int $id): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM Models WHERE ModelID = ?) AS `exists`
        ", [$id]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function existsByNameForBrand(int $brandID, string $name): bool
    {
        $result = DB::select("
            SELECT EXISTS(
                SELECT 1 FROM Models WHERE BrandID = ? AND Name = ?
            ) AS `exists`
        ", [$brandID, $name]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function disable(int $id): bool
    {
        return DB::update("
            UPDATE Models SET IsActive = 0, UpdatedAt = ? WHERE ModelID = ?
        ", [now(), $id]) > 0;
    }

    public function enable(int $id): bool
    {
        return DB::update("
            UPDATE Models SET IsActive = 1, UpdatedAt = ? WHERE ModelID = ?
        ", [now(), $id]) > 0;
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['1=1'];
        $bindings = [];

        if (!empty($filters['search'])) {
            $where[] = '(m.Name LIKE ? OR m.Code LIKE ?)';
            $term = '%' . $filters['search'] . '%';
            $bindings[] = $term;
            $bindings[] = $term;
        }

        if (isset($filters['isActive'])) {
            $where[] = 'm.IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        if (!empty($filters['brandID'])) {
            $where[] = 'm.BrandID = ?';
            $bindings[] = $filters['brandID'];
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'Name');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM Models m WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT m.*, b.Name AS BrandName
            FROM Models m
            JOIN Brands b ON b.BrandID = m.BrandID
            WHERE {$whereSql}
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

    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['m.IsActive = 1'];
        $bindings = [];

        if (!empty($filters['id'])) {
            $where[] = 'm.ModelID = ?';
            $bindings[] = $filters['id'];
        }

        if (!empty($filters['brandID'])) {
            $where[] = 'm.BrandID = ?';
            $bindings[] = $filters['brandID'];
        }

        if (!empty($filters['name'])) {
            $where[] = 'm.Name LIKE ?';
            $bindings[] = '%' . $filters['name'] . '%';
        }

        $whereSql = implode(' AND ', $where);
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM Models m WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT m.ModelID, m.Name, m.Code, m.ReleaseYear, b.Name AS BrandName
            FROM Models m
            JOIN Brands b ON b.BrandID = m.BrandID
            WHERE {$whereSql}
            ORDER BY m.Name ASC
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

    private function resolveSortColumn(string $sortBy): string
    {
        return match ($sortBy) {
            'CreatedAt'   => 'm.CreatedAt',
            'UpdatedAt'   => 'm.UpdatedAt',
            'IsActive'    => 'm.IsActive',
            'ReleaseYear' => 'm.ReleaseYear',
            default       => 'm.Name',
        };
    }
}