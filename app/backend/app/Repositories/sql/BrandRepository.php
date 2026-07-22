<?php

namespace App\Repositories\sql;

use App\DTOs\Brand\CreateBrandDto;
use App\DTOs\Brand\UpdateBrandDto;
use App\Repositories\Interface\BrandRepositoryInterface;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class BrandRepository implements BrandRepositoryInterface
{
    public function create(CreateBrandDto $dto): ?object
    {
        try {
            DB::select('CALL SP_CreateBrand(?, ?, ?, ?, ?, @brandId)', [
                $dto->name,
                $dto->logoUrl,
                $dto->website,
                $dto->description,
                $dto->countryID,
            ]);
            $result = DB::select('SELECT @brandId AS BrandID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $this->findById((int) $result[0]->BrandID);
    }

    public function createByName(string $name): int
    {
        try {
            DB::select('CALL SP_CreateBrandByName(?, @brandId)', [$name]);
            $result = DB::select('SELECT @brandId AS BrandID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return (int) $result[0]->BrandID;
    }

    /**
     * SP_CreateBrand / SP_CreateBrandByName use SIGNAL SQLSTATE '45000'
     * for the "unknown country" check. errorInfo[2] carries the
     * MESSAGE_TEXT set in the SIGNAL statement.
     */
    private function translateSqlException(QueryException $e): \Throwable
    {
        $sqlState = $e->errorInfo[0] ?? null;

        if ($sqlState === '45000') {
            $message = $e->errorInfo[2] ?? 'Une erreur est survenue lors de la création de la marque.';
            return new BusinessValidationException($message, 422, $e);
        }

        if (($e->errorInfo[0] ?? null) === '23000' && ($e->errorInfo[1] ?? null) === 1062) {
            return new BusinessValidationException('Une marque avec ce nom existe déjà.', 422, $e);
        }

        return $e;
    }

    public function update(int $id, UpdateBrandDto $dto): bool
    {
        $slug = Str::slug($dto->name) . '-' . $id;

        try {
            $updated = DB::update("
                UPDATE Brands
                SET
                    Name = ?,
                    Slug = ?,
                    LogoURL = ?,
                    Website = ?,
                    Description = ?,
                    CountryID = ?,
                    UpdatedAt = ?
                WHERE BrandID = ?
            ", [
                $dto->name,
                $slug,
                $dto->logoUrl,
                $dto->website,
                $dto->description,
                $dto->countryID,
                now(),
                $id
            ]);
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $updated > 0;
    }

    public function findById(int $id): ?object
    {
        $brand = DB::select("
            SELECT b.*, c.Name AS CountryName
            FROM Brands b
            LEFT JOIN Countries c ON c.CountryID = b.CountryID
            WHERE b.BrandID = ?
        ", [$id]);

        return $brand[0] ?? null;
    }

    public function existsById(int $id): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM Brands WHERE BrandID = ?) AS `exists`
        ", [$id]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function existsByName(string $name): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM Brands WHERE Name = ?) AS `exists`
        ", [$name]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function disable(int $id): bool
    {
        return DB::update("
            UPDATE Brands SET IsActive = 0, UpdatedAt = ? WHERE BrandID = ?
        ", [now(), $id]) > 0;
    }

    public function enable(int $id): bool
    {
        return DB::update("
            UPDATE Brands SET IsActive = 1, UpdatedAt = ? WHERE BrandID = ?
        ", [now(), $id]) > 0;
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['1=1'];
        $bindings = [];

        if (!empty($filters['search'])) {
            $where[] = '(b.Name LIKE ? OR b.Slug LIKE ?)';
            $term = '%' . $filters['search'] . '%';
            $bindings[] = $term;
            $bindings[] = $term;
        }

        if (isset($filters['isActive'])) {
            $where[] = 'b.IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        if (!empty($filters['countryID'])) {
            $where[] = 'b.CountryID = ?';
            $bindings[] = $filters['countryID'];
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'Name');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM Brands b WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT b.*, c.Name AS CountryName
            FROM Brands b
            LEFT JOIN Countries c ON c.CountryID = b.CountryID
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

    /**
     * Public listing: name wildcard only, active brands only, minimal columns.
     */
    public function getAllPublic(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['b.IsActive = 1'];
        $bindings = [];

        if (!empty($filters['id'])) {
            $where[] = 'b.BrandID = ?';
            $bindings[] = $filters['id'];
        }

        if (!empty($filters['name'])) {
            $where[] = 'b.Name LIKE ?';
            $bindings[] = '%' . $filters['name'] . '%';
        }

        $whereSql = implode(' AND ', $where);
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM Brands b WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT b.BrandID, b.Name, b.Slug, b.LogoURL
            FROM Brands b
            WHERE {$whereSql}
            ORDER BY b.Name ASC
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
            'CreatedAt' => 'b.CreatedAt',
            'UpdatedAt' => 'b.UpdatedAt',
            'IsActive'  => 'b.IsActive',
            default     => 'b.Name',
        };
    }
}