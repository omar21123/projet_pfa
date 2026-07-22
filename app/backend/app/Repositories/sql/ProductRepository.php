<?php

namespace App\Repositories\sql;

use App\DTOs\Product\BlockProductDto;
use App\DTOs\Product\CreateProductDto;
use App\Repositories\Interface\ProductRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;
use App\DTOs\Product\GetAllProductsAdminDto;
use App\DTOs\Product\PaginatedProductAdminResponseDto;
use App\DTOs\Product\ProductAdminResponseDto;
use App\DTOs\Product\ProductDetailsDto;
use App\DTOs\Product\RefuseProductDto;
use App\DTOs\Product\RefuseProductResultDto;
use App\DTOs\Product\ValidateProductDto;

class ProductRepository implements ProductRepositoryInterface
{
    public function create(CreateProductDto $dto): ?object
    {
        return DB::transaction(function () use ($dto) {

            // 1) Create the product
            DB::select('CALL SP_CreateProduct(?, ?, ?, ?, ?, ?, ?, ?, @productId, @success, @message)', [
                $dto->vendorID,
                $dto->brandID,
                $dto->modelID,
                $dto->name,
                $dto->barcode,
                $dto->description,
                $dto->basePrice,
                $dto->stock,
            ]);

            $result = DB::selectOne('SELECT @productId AS productId, @success AS success, @message AS message');

            if (!$result->success) {
                throw new BusinessValidationException($result->message, 422);
            }

            $productId = (int) $result->productId;

            // 2) Resources
            foreach ($dto->resources as $resource) {
                DB::select('CALL SP_CreateProductResource(?, ?, ?, ?, @resourceId, @success, @message)', [
                    $productId,
                    $resource->type,
                    $resource->role,
                    $resource->path,
                ]);

                $result = DB::selectOne('SELECT @resourceId AS resourceId, @success AS success, @message AS message');

                if (!$result->success) {
                    throw new BusinessValidationException($result->message, 422);
                }
            }

            // 3) Categories
            foreach ($dto->categories as $categoryId) {
                DB::select('CALL SP_CreateProductCategory(?, ?, @success, @message)', [
                    $productId,
                    $categoryId,
                ]);

                $result = DB::selectOne('SELECT @success AS success, @message AS message');

                if (!$result->success) {
                    throw new BusinessValidationException($result->message, 422);
                }
            }

            // 4) Attributes + ConfigOptions
            foreach ($dto->attributes as $attribute) {
                $result = DB::select('CALL SP_GetOrCreateProductsConfigAttributeByName(?, @attributeId, @success, @message)', [
                    $attribute->configName,
                ]);

                $result = $result[0] ?? null;

                if (!$result || !$result->Success) {
                    throw new BusinessValidationException($result->Message ?? 'Erreur lors de la récupération de l\'attribut.', 422);
                }

                $attributeId = (int) $result->AttributeID;

                foreach ($attribute->configOptions as $option) {
                    DB::select('CALL SP_CreateProductDetailByOptionName(?, ?, ?, ?, @detailId, @optionId, @success, @message)', [
                        $productId,
                        $attributeId,
                        $option->name,
                        $option->isDefault ? 1 : 0,
                    ]);

                    $result = DB::selectOne('SELECT @detailId AS detailId, @optionId AS optionId, @success AS success, @message AS message');

                    if (!$result->success) {
                        throw new BusinessValidationException($result->message, 422);
                    }
                }
            }

            // 5) Tags
            foreach ($dto->tags as $tagName) {
                DB::select('CALL SP_AddProductTagByName(?, ?, @tagId, @success, @message)', [
                    $productId,
                    $tagName,
                ]);

                $result = DB::selectOne('SELECT @tagId AS tagId, @success AS success, @message AS message');

                if (!$result->success) {
                    throw new BusinessValidationException($result->message, 422);
                }
            }

            // 6) Allowed Payments
            foreach ($dto->allowedPayment as $paymentMethodId) {
                DB::insert('INSERT INTO ProductAllowedPayements (ProductID, PayementMethodID) VALUES (?, ?)', [
                    $productId,
                    $paymentMethodId,
                ]);
            }

            // 7) Return the created product
            return DB::selectOne('SELECT * FROM Products WHERE ProductID = ?', [$productId]);
        });
    }

    public function getAllProductsAdmin(GetAllProductsAdminDto $dto): PaginatedProductAdminResponseDto
    {
        $rows = DB::select(
            'CALL SP_GetAllProductsAdmin(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @totalCount, @success, @message)',
            [
                $dto->status,
                $dto->vendorId,
                $dto->brandId,
                $dto->modelId,
                $dto->search,
                $dto->isActive === null ? null : (int) $dto->isActive,
                $dto->isBlocked === null ? null : (int) $dto->isBlocked,
                $dto->dateFrom,
                $dto->dateTo,
                $dto->pageNumber,
                $dto->pageSize,
            ]
        );

        $result = DB::selectOne('SELECT @totalCount AS totalCount, @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        $items = array_map(fn($row) => ProductAdminResponseDto::fromRow($row), $rows);

        return new PaginatedProductAdminResponseDto(
            items: $items,
            total: (int) $result->totalCount,
            page: $dto->pageNumber,
            pageSize: $dto->pageSize,
        );
    }

    public function getProductDetails(int $productId): ProductDetailsDto
    {
        $pdo = DB::connection()->getPdo();

        $stmt = $pdo->prepare('CALL SP_GetProductDetails(?, @success, @message)');
        $stmt->bindValue(1, $productId, \PDO::PARAM_INT);
        $stmt->execute();

        // Resultset 1: details (only present when the product exists)
        $detailsRows = $stmt->fetchAll(\PDO::FETCH_OBJ);
        $details = $detailsRows[0] ?? null;

        $tags = $allowedPayments = $categories = $configs = $resources = [];

        if ($details) {
            $stmt->nextRowset();
            $tags = $stmt->fetchAll(\PDO::FETCH_OBJ);

            $stmt->nextRowset();
            $allowedPayments = $stmt->fetchAll(\PDO::FETCH_OBJ);

            $stmt->nextRowset();
            $categories = $stmt->fetchAll(\PDO::FETCH_OBJ);

            $stmt->nextRowset();
            $configs = $stmt->fetchAll(\PDO::FETCH_OBJ);

            // 🎯 6e resultset : images/vidéos du produit (à ajouter côté SP, voir note plus bas)
            $stmt->nextRowset();
            $resources = $stmt->fetchAll(\PDO::FETCH_OBJ);
        }

        // Drain any remaining rowsets (CALL statements sometimes emit a trailing
        // empty one) before the connection can be reused safely.
        while ($stmt->nextRowset()) {
            // no-op, just draining
        }

        $stmt->closeCursor();

        $out = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$out->success) {
            throw new BusinessValidationException($out->message, 422);
        }

        return new ProductDetailsDto(
            details: $details,
            tags: $tags,
            allowedPayments: $allowedPayments,
            categories: $categories,
            configs: $configs,
            resources: $resources,
        );
    }
    public function validate(ValidateProductDto $dto): void
    {
        DB::select('CALL SP_ValidateProduct(?, ?, ?, @success, @message)', [
            $dto->productId,
            $dto->validatorId,
            $dto->notes,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }
    }
    public function block(BlockProductDto $dto): void
    {
        DB::select('CALL SP_BlockProduct(?, ?, ?, @success, @message)', [
            $dto->productId,
            $dto->blockedBy,
            $dto->notes,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }
    }
    public function isExistsByID(int $productID): bool
    {
        $result = DB::selectOne('SELECT 1 AS Found FROM Products WHERE ProductID = ?', [$productID]);

        return !empty($result);
    }
    public function refuse(RefuseProductDto $dto): RefuseProductResultDto
    {
        DB::select('CALL SP_RefuseProduct(?, ?, ?, @success, @message, @autoBlocked)', [
            $dto->productId,
            $dto->refusedBy,
            $dto->notes,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message, @autoBlocked AS autoBlocked');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        return new RefuseProductResultDto(
            message: $result->message,
            autoBlocked: (bool) $result->autoBlocked,
        );
    }
}