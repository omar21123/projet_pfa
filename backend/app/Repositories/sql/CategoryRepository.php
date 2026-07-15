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
        return DB::update("
        UPDATE Categories
        SET
            IsActive = 1,
            UpdatedAt = ?
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

    public function delete(int $id): bool
    {
        return DB::delete("
            DELETE FROM Categories
            WHERE CategoryID = ?
        ", [$id]) > 0;
    }

    public function getRootCategories(array $filters = [], int $page = 1, int $perPage = 20): array
    {
        $where = ['c.ParentCategoryID IS NULL'];
        $bindings = [];

        if (!empty($filters['search'])) {
            $where[] = '(c.Name LIKE ? OR c.Slug LIKE ?)';
            $searchTerm = '%' . $filters['search'] . '%';
            $bindings[] = $searchTerm;
            $bindings[] = $searchTerm;
        }

        if (isset($filters['isActive'])) {
            $where[] = 'c.IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        if (!empty($filters['hasProducts'])) {
            // only categories with at least one product, direct or in descendants
            $where[] = '(SELECT COUNT(*) FROM ProductCategories pc
                        JOIN CategoryClosure cc ON cc.DescendantID = pc.CategoryID
                        WHERE cc.AncestorID = c.CategoryID) > 0';
        }

        if (!empty($filters['isEmpty'])) {
            // inverse: categories with zero products in their subtree
            $where[] = '(SELECT COUNT(*) FROM ProductCategories pc
                        JOIN CategoryClosure cc ON cc.DescendantID = pc.CategoryID
                        WHERE cc.AncestorID = c.CategoryID) = 0';
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'DisplayOrder');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';

        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
        SELECT COUNT(*) AS aggregate
        FROM Categories c
        WHERE {$whereSql}
    ", $bindings)->aggregate;

        $rows = DB::select("
        SELECT
            c.CategoryID,
            c.Name,
            c.Slug,
            c.IconURL,
            c.IsActive,
            c.DisplayOrder,
            c.CreatedAt,
            c.UpdatedAt,
            (SELECT COUNT(*) FROM CategoryClosure cc
                WHERE cc.AncestorID = c.CategoryID AND cc.Depth = 1)  AS DirectChildrenCount,
            (SELECT COUNT(*) FROM ProductCategories pc
                JOIN CategoryClosure cc ON cc.DescendantID = pc.CategoryID
                WHERE cc.AncestorID = c.CategoryID)                   AS TotalProductsCount,
            (SELECT COUNT(*) FROM ProductCategories pc
                WHERE pc.CategoryID = c.CategoryID)                   AS DirectProductsCount
        FROM Categories c
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

    public function getChildren(int $parentId, array $filters = [], int $page = 1, int $perPage = 50): array
    {
        $where = ['c.ParentCategoryID = ?'];
        $bindings = [$parentId];

        if (!empty($filters['search'])) {
            $where[] = '(c.Name LIKE ? OR c.Slug LIKE ?)';
            $searchTerm = '%' . $filters['search'] . '%';
            $bindings[] = $searchTerm;
            $bindings[] = $searchTerm;
        }

        if (isset($filters['isActive'])) {
            $where[] = 'c.IsActive = ?';
            $bindings[] = $filters['isActive'] ? 1 : 0;
        }

        $whereSql = implode(' AND ', $where);

        $sortColumn = $this->resolveSortColumn($filters['sortBy'] ?? 'DisplayOrder');
        $sortDir = ($filters['sortDir'] ?? 'asc') === 'desc' ? 'DESC' : 'ASC';

        $offset = ($page - 1) * $perPage;

        $total = DB::selectOne("
        SELECT COUNT(*) AS aggregate
        FROM Categories c
        WHERE {$whereSql}
    ", $bindings)->aggregate;

        $rows = DB::select("
        SELECT
            c.CategoryID,
            c.Name,
            c.Slug,
            p.Name AS ParentCategoryName,
            c.IconURL,
            c.IsActive,
            c.DisplayOrder,
            c.CreatedAt,
            c.UpdatedAt,
            (SELECT COUNT(*) FROM CategoryClosure cc
                WHERE cc.AncestorID = c.CategoryID AND cc.Depth = 1)  AS DirectChildrenCount,
            (SELECT COUNT(*) FROM ProductCategories pc
                JOIN CategoryClosure cc ON cc.DescendantID = pc.CategoryID
                WHERE cc.AncestorID = c.CategoryID)                   AS TotalProductsCount,
            (SELECT COUNT(*) FROM ProductCategories pc
                WHERE pc.CategoryID = c.CategoryID)                   AS DirectProductsCount
        FROM Categories c
        LEFT JOIN Categories p ON p.CategoryID = c.ParentCategoryID
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
     * Whitelist sortable columns to prevent SQL injection via sortBy —
     * never interpolate a client-supplied column name directly.
     */
    private function resolveSortColumn(string $sortBy): string
    {
        return match ($sortBy) {
            'Name' => 'c.Name',
            'CreatedAt' => 'c.CreatedAt',
            'UpdatedAt' => 'c.UpdatedAt',
            default => 'c.DisplayOrder',
        };
    }
    public function propagateInactivation(int $id): bool
    {
        return DB::update("
        UPDATE Categories
        SET
            IsActive = 0,
            UpdatedAt = ?
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
    public function activate(int $id): bool
{
    return DB::update("
        UPDATE Categories
        SET
            IsActive = 1,
            UpdatedAt = ?
        WHERE CategoryID = ?
    ", [
        now(),
        $id
    ]) > 0;
}
   public function getNavbarCategories(): array
{
    $rows = DB::select("CALL SP_GetNavbarCategories()");
    return $this->buildTree($rows);
}
private function buildTree(array $rows): array
{
    $nodes = [];
    $tree = [];

    // Création d'un tableau indexé par CategoryID
    foreach ($rows as $row) {
        $row->children = [];
        $nodes[$row->CategoryID] = $row;
    }

    // Construction de l'arbre
    foreach ($nodes as $node) {

        if ($node->ParentCategoryID === null) {

            $tree[] = $node;

        } elseif (isset($nodes[$node->ParentCategoryID])) {

            $nodes[$node->ParentCategoryID]->children[] = $node;

        }

    }

    return $tree;
}

}
