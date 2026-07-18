<?php

namespace App\Repositories\sql;

use App\DTOs\ProductsConfigAttribute\CreateProductsConfigAttributeDto;
use App\DTOs\ProductsConfigAttribute\UpdateProductsConfigAttributeDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\ProductsConfigAttributeRepositoryInterface;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class ProductsConfigAttributeRepository implements ProductsConfigAttributeRepositoryInterface
{
    public function create(CreateProductsConfigAttributeDto $dto): ?object
    {
        try {
            DB::select('CALL SP_CreateProductsConfigAttribute(?, ?, ?, @attributeId)', [
                $dto->name,
                $dto->unitID,
                $dto->displayOrder,
            ]);
            $result = DB::select('SELECT @attributeId AS AttributeID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $this->findById((int) $result[0]->AttributeID);
    }

    public function createByName(string $name): int
    {
        try {
            DB::select('CALL SP_CreateProductsConfigAttributeByName(?, @attributeId)', [$name]);
            $result = DB::select('SELECT @attributeId AS AttributeID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return (int) $result[0]->AttributeID;
    }

    /**
     * SP_CreateProductsConfigAttribute uses SIGNAL SQLSTATE '45000'
     * for the "unknown unit" check. errorInfo[2] carries the
     * MESSAGE_TEXT set in the SIGNAL statement.
     */
    private function translateSqlException(QueryException $e): \Throwable
    {
        $sqlState = $e->errorInfo[0] ?? null;

        if ($sqlState === '45000') {
            $message = $e->errorInfo[2] ?? 'Une erreur est survenue lors de la création de l\'attribut.';
            return new BusinessValidationException($message, 422, $e);
        }

        if (($e->errorInfo[0] ?? null) === '23000' && ($e->errorInfo[1] ?? null) === 1062) {
            return new BusinessValidationException('Un attribut avec ce nom existe déjà.', 422, $e);
        }

        return $e;
    }

    public function update(int $id, UpdateProductsConfigAttributeDto $dto): bool
    {
        try {
            $updated = DB::update("
                UPDATE ProductsConfigAttribute
                SET
                    Name = ?,
                    UnitID = ?,
                    DisplayOrder = ?,
                    UpdatedAt = ?
                WHERE AttributeID = ?
            ", [
                $dto->name,
                $dto->unitID,
                $dto->displayOrder,
                now(),
                $id,
            ]);
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $updated > 0;
    }

    public function findById(int $id): ?object
    {
        $attribute = DB::select("
            SELECT a.*, u.Name AS UnitName
            FROM ProductsConfigAttribute a
            LEFT JOIN Units u ON u.UnitID = a.UnitID
            WHERE a.AttributeID = ?
        ", [$id]);

        return $attribute[0] ?? null;
    }

    public function existsById(int $id): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM ProductsConfigAttribute WHERE AttributeID = ?) AS `exists`
        ", [$id]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function existsByName(string $name): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM ProductsConfigAttribute WHERE Name = ?) AS `exists`
        ", [$name]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function disable(int $id): bool
    {
        return DB::update("
            UPDATE ProductsConfigAttribute SET IsActive = 0, UpdatedAt = ? WHERE AttributeID = ?
        ", [now(), $id]) > 0;
    }

    public function enable(int $id): bool
    {
        return DB::update("
            UPDATE ProductsConfigAttribute SET IsActive = 1, UpdatedAt = ? WHERE AttributeID = ?
        ", [now(), $id]) > 0;
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['1=1'];
        $bindings = [];

        if (!empty($filters['search'])) {
            $where[] = 'a.Name LIKE ?';
            $bindings[] = '%' . $filters['search'] . '%';
        }

        if (isset($filters['isActive'])) {
            $where[] = 'a.IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        if (!empty($filters['unitID'])) {
            $where[] = 'a.UnitID = ?';
            $bindings[] = $filters['unitID'];
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'Name');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM ProductsConfigAttribute a WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT a.*, u.Name AS UnitName
            FROM ProductsConfigAttribute a
            LEFT JOIN Units u ON u.UnitID = a.UnitID
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
     * Minimal listing: name wildcard only, active attributes only, ID + Name only.
     */
    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['a.IsActive = 1'];
        $bindings = [];

        if (!empty($filters['name'])) {
            $where[] = 'a.Name LIKE ?';
            $bindings[] = '%' . $filters['name'] . '%';
        }

        $whereSql = implode(' AND ', $where);
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM ProductsConfigAttribute a WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT a.AttributeID, a.Name
            FROM ProductsConfigAttribute a
            WHERE {$whereSql}
            ORDER BY a.DisplayOrder ASC, a.Name ASC
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
            'CreatedAt'    => 'a.CreatedAt',
            'UpdatedAt'    => 'a.UpdatedAt',
            'IsActive'     => 'a.IsActive',
            'DisplayOrder' => 'a.DisplayOrder',
            default        => 'a.Name',
        };
    }
    /**
     * All active options for one attribute, ordered for display.
     * Returns full option rows (not just ID+Label) — this is meant
     * to directly populate an attribute's option list/config UI.
     */
    public function getAllOptionsByAttributeID(int $attributeID): array
    {
        return DB::select("
            SELECT o.OptionID, o.OptionLabel, o.OptionValue, o.DisplayOrder, o.IsDefaultForAttribute
            FROM ConfigAttributeOptions o
            WHERE o.ProductsConfigAttributeID = ? AND o.IsActive = 1
            ORDER BY o.DisplayOrder ASC, o.OptionLabel ASC
        ", [$attributeID]);
    }
}