<?php

namespace App\Repositories\sql;

use App\DTOs\Unit\CreateUnitDto;
use App\DTOs\Unit\UpdateUnitDto;
use App\Repositories\Interface\UnitRepositoryInterface;
use Illuminate\Support\Facades\DB;

class UnitRepository implements UnitRepositoryInterface
{
    public function create(CreateUnitDto $dto): ?object
    {
        $id = DB::table('Units')->insertGetId([
            'Name'         => $dto->name,
            'Symbol'       => $dto->symbol,
            'DisplayOrder' => $dto->displayOrder,
        ], 'UnitID');

        return $this->findById($id);
    }

    public function update(int $id, UpdateUnitDto $dto): bool
    {
        return DB::update("
            UPDATE Units
            SET
                Name = ?,
                Symbol = ?,
                DisplayOrder = ?
            WHERE UnitID = ?
        ", [
            $dto->name,
            $dto->symbol,
            $dto->displayOrder,
            $id
        ]) > 0;
    }

    public function findById(int $id): ?object
    {
        $unit = DB::select("
            SELECT * FROM Units WHERE UnitID = ?
        ", [$id]);

        return $unit[0] ?? null;
    }

    public function existsById(int $id): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM Units WHERE UnitID = ?) AS `exists`
        ", [$id]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function existsByName(string $name): bool
    {
        $result = DB::select("
            SELECT EXISTS(SELECT 1 FROM Units WHERE Name = ?) AS `exists`
        ", [$name]);

        return (bool) ($result[0]->exists ?? false);
    }

    public function disable(int $id): bool
    {
        return DB::update("
            UPDATE Units SET IsActive = 0 WHERE UnitID = ?
        ", [$id]) > 0;
    }

    public function enable(int $id): bool
    {
        return DB::update("
            UPDATE Units SET IsActive = 1 WHERE UnitID = ?
        ", [$id]) > 0;
    }

    public function getAllForAdmin(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['1=1'];
        $bindings = [];

        if (!empty($filters['search'])) {
            $where[] = '(Name LIKE ? OR Symbol LIKE ?)';
            $term = '%' . $filters['search'] . '%';
            $bindings[] = $term;
            $bindings[] = $term;
        }

        if (isset($filters['isActive'])) {
            $where[] = 'IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'DisplayOrder');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM Units WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT *
            FROM Units
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
        $where = ['IsActive = 1'];
        $bindings = [];

        if (!empty($filters['id'])) {
            $where[] = 'UnitID = ?';
            $bindings[] = $filters['id'];
        }

        if (!empty($filters['name'])) {
            $where[] = 'Name LIKE ?';
            $bindings[] = '%' . $filters['name'] . '%';
        }

        $whereSql = implode(' AND ', $where);
        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
            SELECT COUNT(*) AS aggregate FROM Units WHERE {$whereSql}
        ", $bindings)->aggregate;

        $rows = DB::select("
            SELECT UnitID, Name, Symbol
            FROM Units
            WHERE {$whereSql}
            ORDER BY DisplayOrder ASC
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
            'Name'     => 'Name',
            'IsActive' => 'IsActive',
            default    => 'DisplayOrder',
        };
    }
}