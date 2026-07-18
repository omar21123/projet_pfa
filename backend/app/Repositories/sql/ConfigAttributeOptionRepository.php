<?php

namespace App\Repositories\sql;

use App\DTOs\ConfigAttributeOption\CreateConfigAttributeOptionDto;
use App\DTOs\ConfigAttributeOption\UpdateConfigAttributeOptionDto;
use App\Exceptions\BusinessValidationException;
use App\Repositories\Interface\ConfigAttributeOptionRepositoryInterface;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class ConfigAttributeOptionRepository implements ConfigAttributeOptionRepositoryInterface
{
    public function create(CreateConfigAttributeOptionDto $dto): ?object
    {
        try {
            DB::select('CALL SP_CreateConfigAttributeOption(?, ?, ?, ?, ?, @optionId)', [
                $dto->productsConfigAttributeID,
                $dto->optionLabel,
                $dto->optionValue,
                $dto->displayOrder,
                $dto->isDefaultForAttribute ? 1 : 0,
            ]);
            $result = DB::select('SELECT @optionId AS OptionID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return $this->findById((int) $result[0]->OptionID);
    }

    public function createByName(int $attributeID, string $optionLabel): int
    {
        try {
            DB::select('CALL SP_CreateConfigAttributeOptionByName(?, ?, @optionId)', [
                $attributeID,
                $optionLabel,
            ]);
            $result = DB::select('SELECT @optionId AS OptionID');
        } catch (QueryException $e) {
            throw $this->translateSqlException($e);
        }

        return (int) $result[0]->OptionID;
    }

    /**
     * SP_CreateConfigAttributeOption(ByName) uses SIGNAL SQLSTATE '45000'
     * for the "unknown attribute" check. errorInfo[2] carries the
     * MESSAGE_TEXT set in the SIGNAL statement.
     */
    private function translateSqlException(QueryException $e): \Throwable
    {
        $sqlState = $e->errorInfo[0] ?? null;

        if ($sqlState === '45000') {
            $message = $e->errorInfo[2] ?? 'Une erreur est survenue lors de la création de l\'option.';
            return new BusinessValidationException($message, 422, $e);
        }

        if (($e->errorInfo[0] ?? null) === '23000' && ($e->errorInfo[1] ?? null) === 1062) {
            return new BusinessValidationException('Une option avec ce libellé existe déjà pour cet attribut.', 422, $e);
        }

        return $e;
    }

    public function update(int $id, UpdateConfigAttributeOptionDto $dto): bool
    {
        try {
            if ($dto->isDefaultForAttribute) {
                DB::update("
                    UPDATE ConfigAttributeOptions
                    SET IsDefaultForAttribute = 0
                    WHERE ProductsConfigAttributeID = ? AND OptionID != ?
                ", [$dto->productsConfigAttributeID, $id]);
            }

            $updated = DB::update("
                UPDATE ConfigAttributeOptions
                SET
                    ProductsConfigAttributeID = ?,
                    OptionLabel = ?,
                    OptionValue = ?,
                    DisplayOrder = ?,
                    IsDefaultForAttribute = ?,
                    UpdatedAt = ?
                WHERE OptionID = ?
            ", [
                $dto->productsConfigAttributeID,
                $dto->optionLabel,
                $dto->optionValue,
                $dto->displayOrder,
                $dto->isDefaultForAttribute ? 1 : 0,
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
        $option = DB::select("
            SELECT o.*, a.Name AS AttributeName
            FROM ConfigAttributeOptions o
            LEFT JOIN ProductsConfigAttribute a ON a.AttributeID = o.ProductsConfigAttributeID
            WHERE o.OptionID = ?
        ", [$id]);

        return $option[0] ?? null;
    }

    public function existsById(int $id): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM ConfigAttributeOptions WHERE OptionID = ?) AS `exists`
        ", [$id]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function existsByName(int $attributeID, string $optionLabel): bool
    {
        $result = DB::select("
            SELECT EXISTS(
                SELECT 1 FROM ConfigAttributeOptions
                WHERE ProductsConfigAttributeID = ? AND OptionLabel = ?
            ) AS `exists`
        ", [$attributeID, $optionLabel]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function disable(int $id): bool
    {
        return DB::update("
            UPDATE ConfigAttributeOptions SET IsActive = 0, UpdatedAt = ? WHERE OptionID = ?
        ", [now(), $id]) > 0;
    }

    public function enable(int $id): bool
    {
        return DB::update("
            UPDATE ConfigAttributeOptions SET IsActive = 1, UpdatedAt = ? WHERE OptionID = ?
        ", [now(), $id]) > 0;
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['1=1'];
        $bindings = [];

        if (!empty($filters['search'])) {
            $where[] = '(o.OptionLabel LIKE ? OR o.OptionValue LIKE ?)';
            $term = '%' . $filters['search'] . '%';
            $bindings[] = $term;
            $bindings[] = $term;
        }

        if (isset($filters['isActive'])) {
            $where[] = 'o.IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        if (!empty($filters['productsConfigAttributeID'])) {
            $where[] = 'o.ProductsConfigAttributeID = ?';
            $bindings[] = $filters['productsConfigAttributeID'];
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'DisplayOrder');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM ConfigAttributeOptions o WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT o.*, a.Name AS AttributeName
            FROM ConfigAttributeOptions o
            LEFT JOIN ProductsConfigAttribute a ON a.AttributeID = o.ProductsConfigAttributeID
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
     * Minimal listing: ID + Label only, active options only.
     * ProductsConfigAttributeID filter is expected in practice
     * (options only make sense scoped to their attribute) but not enforced.
     */
    public function getAll(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['o.IsActive = 1'];
        $bindings = [];

        if (!empty($filters['productsConfigAttributeID'])) {
            $where[] = 'o.ProductsConfigAttributeID = ?';
            $bindings[] = $filters['productsConfigAttributeID'];
        }

        if (!empty($filters['name'])) {
            $where[] = 'o.OptionLabel LIKE ?';
            $bindings[] = '%' . $filters['name'] . '%';
        }

        $whereSql = implode(' AND ', $where);
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM ConfigAttributeOptions o WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT o.OptionID, o.OptionLabel
            FROM ConfigAttributeOptions o
            WHERE {$whereSql}
            ORDER BY o.DisplayOrder ASC, o.OptionLabel ASC
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
    private function resolveSortColumn(string $sortBy): string
    {
        return match ($sortBy) {
            'CreatedAt'    => 'o.CreatedAt',
            'UpdatedAt'    => 'o.UpdatedAt',
            'IsActive'     => 'o.IsActive',
            'OptionLabel'  => 'o.OptionLabel',
            default        => 'o.DisplayOrder',
        };
    }
}