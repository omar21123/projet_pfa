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
use App\DTOs\Product\ProductCombinationDto;
use App\DTOs\Product\ProductCombinationDetailDto;
use App\DTOs\Product\UpdateProductCombinationDto;
use App\Exceptions\NotFoundException; // adapte si tu as une exception dédiée 404
use App\DTOs\Product\vendor\GetVendorProductsDto;
use App\DTOs\Product\vendor\PaginatedVendorProductResponseDto;
use App\DTOs\Product\vendor\VendorProductItemDto;

// ProductRepository — add this method alongside getProductsForVendor()
use App\DTOs\Product\SearchProductsByTermDto;
use App\DTOs\Product\PaginatedProductItemResponseDto;
use App\DTOs\Product\ProductInfoAllowedPaymentDto;
use App\DTOs\Product\ProductInfoCategoryDto;
use App\DTOs\Product\ProductInfoCombinationConfigDto;
use App\DTOs\Product\ProductInfoCombinationDto;
use App\DTOs\Product\ProductInfoConfigDto;
use App\DTOs\Product\ProductInfoConfigOptionDto;
use App\DTOs\Product\ProductInfoPromotionDto;
use App\DTOs\Product\ProductInfoTagDto;
use App\DTOs\Product\ProductItemDto;
use App\DTOs\Product\ProductSearchResultDto;
use App\DTOs\Product\PublicProductInfoDto;
use Illuminate\Support\Facades\Log;

class ProductRepository implements ProductRepositoryInterface
{


    public function create(CreateProductDto $dto): ?object
    {
        return DB::transaction(function () use ($dto) {

            Log::info("========== CREATE PRODUCT START ==========");

            // 1) Product
            Log::info("STEP 1 - Create Product", [
                'vendorID' => $dto->vendorID,
                'brandID' => $dto->brandID,
                'modelID' => $dto->modelID,
                'name' => $dto->name,
                'barcode' => $dto->barcode,
            ]);

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

            Log::info("STEP 1 RESULT", (array) $result);

            if (!$result->success) {
                throw new BusinessValidationException($result->message, 422);
            }

            $productId = (int) $result->productId;

            // 2) Resources
            Log::info("STEP 2 - Resources");

            foreach ($dto->resources as $resource) {

                Log::info("Resource", (array) $resource);

                DB::select('CALL SP_CreateProductResource(?, ?, ?, ?, @resourceId, @success, @message)', [
                    $productId,
                    $resource->type,
                    $resource->role,
                    $resource->path,
                ]);

                $result = DB::selectOne('SELECT @resourceId AS resourceId, @success AS success, @message AS message');

                Log::info("Resource Result", (array) $result);

                if (!$result->success) {
                    throw new BusinessValidationException($result->message, 422);
                }
            }

            // 3) Categories
            Log::info("STEP 3 - Categories");

            foreach ($dto->categories as $categoryId) {

                Log::info("Category", ['id' => $categoryId]);

                DB::select('CALL SP_CreateProductCategory(?, ?, @success, @message)', [
                    $productId,
                    $categoryId
                ]);

                $result = DB::selectOne('SELECT @success AS success, @message AS message');

                Log::info("Category Result", (array) $result);

                if (!$result->success) {
                    throw new BusinessValidationException($result->message, 422);
                }
            }

            // 4) Attributes
            Log::info("STEP 4 - Attributes");

            $optionMap = [];

            foreach ($dto->attributes as $attribute) {

                Log::info("Attribute", (array) $attribute);

                $result = DB::select('CALL SP_GetOrCreateProductsConfigAttributeByName(?, @attributeId, @success, @message)', [
                    $attribute->configName,
                ]);

                $result = $result[0] ?? null;

                Log::info("Attribute Result", (array) $result);

                if (!$result || !$result->Success) {
                    throw new BusinessValidationException(
                        $result->Message ?? 'Erreur attribut',
                        422
                    );
                }

                $attributeId = (int) $result->AttributeID;

                $optionMap[$attribute->configName] = [];

                foreach ($attribute->configOptions as $option) {

                    Log::info("Option", (array) $option);

                    DB::select('CALL SP_CreateProductDetailByOptionName(?, ?, ?, ?, @detailId, @optionId, @success, @message)', [
                        $productId,
                        $attributeId,
                        $option->name,
                        $option->isDefault ? 1 : 0,
                    ]);

                    $res = DB::selectOne('SELECT @detailId AS detailId,@optionId AS optionId,@success AS success,@message AS message');

                    Log::info("Option Result", (array) $res);

                    if (!$res->success) {
                        throw new BusinessValidationException($res->message, 422);
                    }

                    $optionMap[$attribute->configName][$option->name] = [
                        'attributeId' => $attributeId,
                        'optionId' => (int) $res->optionId
                    ];
                }
            }

            // 5) Combinations
            Log::info("STEP 5 - Combinations");

            foreach ($dto->combinations as $combination) {

                Log::info("Combination", (array) $combination);

                $optionsPairs = [];

                foreach ($combination->options as $opt) {

                    Log::info("Combination Option", (array) $opt);

                    if (!isset($optionMap[$opt->configName][$opt->optionName])) {
                        throw new BusinessValidationException(
                            "Option introuvable : {$opt->configName} -> {$opt->optionName}",
                            422
                        );
                    }

                    $optionsPairs[] = $optionMap[$opt->configName][$opt->optionName];
                }

                Log::info("Options JSON", $optionsPairs);

                DB::select('CALL SP_CreateProductCombination(?, ?, ?, ?, ?, ?, ?, ?, @combinationId, @success, @message)', [
                    $productId,
                    $combination->sku,
                    $combination->price,
                    $combination->compareAtPrice,
                    $combination->stock,
                    $combination->imagePath,
                    $combination->isDefault ? 1 : 0,
                    json_encode($optionsPairs),
                ]);

                $res = DB::selectOne('SELECT @combinationId AS combinationId,@success AS success,@message AS message');

                Log::info("Combination Result", (array) $res);

                if (!$res->success) {
                    throw new BusinessValidationException($res->message, 422);
                }
            }

            Log::info("========== CREATE PRODUCT SUCCESS ==========");

            return DB::selectOne(
                'SELECT * FROM Products WHERE ProductID=?',
                [$productId]
            );
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

    public function getProductCombinationsForVendor(string $userPublicId, int $productId): array
    {
        $rows = DB::select('CALL SP_GetProductCombinationsForVendor(?, ?)', [
            $userPublicId,
            $productId,
        ]);

        return ProductCombinationDto::fromRows($rows);
    }


    public function getCombinationById(string $userPublicId, int $combinationId): ProductCombinationDetailDto
    {
        $pdo = DB::connection()->getPdo();

        $stmt = $pdo->prepare('CALL SP_GetProductCombinationByID(?, ?, @success, @message)');
        $stmt->bindValue(1, $userPublicId, \PDO::PARAM_STR);
        $stmt->bindValue(2, $combinationId, \PDO::PARAM_INT);
        $stmt->execute();

        $combinationRows = $stmt->fetchAll(\PDO::FETCH_OBJ);
        $combinationRow = $combinationRows[0] ?? null;

        $optionRows = [];
        if ($combinationRow) {
            $stmt->nextRowset();
            $optionRows = $stmt->fetchAll(\PDO::FETCH_OBJ);
        }

        while ($stmt->nextRowset()) {
            // drain
        }
        $stmt->closeCursor();

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'Accès refusé') ? 403 : 404;
            throw new BusinessValidationException($result->message, $status);
        }

        return ProductCombinationDetailDto::fromRow($combinationRow, $optionRows);
    }

    public function updateCombination(UpdateProductCombinationDto $dto): ProductCombinationDetailDto
    {
        DB::select('CALL SP_UpdateProductCombination(?, ?, ?, ?, ?, ?, ?, ?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->combinationId,
            $dto->sku,
            $dto->price,
            $dto->compareAtPrice,
            $dto->stock,
            $dto->imagePath,
            $dto->isDefault ? 1 : 0,
            $dto->isActive ? 1 : 0,
        ]);

        $row = DB::selectOne('SELECT * FROM ProductOptionsCombiniason WHERE CombinationID = ?', [$dto->combinationId]);
        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'Accès refusé') ? 403 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        return ProductCombinationDetailDto::fromRow($row);
    }


    public function getProductsForVendor(GetVendorProductsDto $dto): PaginatedVendorProductResponseDto
    {
        $rows = DB::select(
            'CALL SP_GetProductsForVendor(?, ?, ?, ?, ?, ?, ?, @totalCount, @success, @message)',
            [
                $dto->userPublicId,
                $dto->status,
                $dto->search,
                $dto->isActive === null ? null : (int) $dto->isActive,
                $dto->isBlocked === null ? null : (int) $dto->isBlocked,
                $dto->pageNumber,
                $dto->pageSize,
            ]
        );

        $result = DB::selectOne('SELECT @totalCount AS totalCount, @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        $items = array_map(fn($row) => VendorProductItemDto::fromRow($row), $rows);
        
        return new PaginatedVendorProductResponseDto(
            items: $items,
            total: (int) $result->totalCount,
            page: $dto->pageNumber,
            pageSize: $dto->pageSize,
        );
    }



    public function searchByTerm(SearchProductsByTermDto $dto): PaginatedProductItemResponseDto
    {
        $rows = DB::select(
            'CALL SP_SearchProductsByTerm(?, ?, ?, ?, @totalCount, @success, @message)',
            [
                $dto->query,
                $dto->userPublicId,
                $dto->pageNumber,
                $dto->pageSize,
            ]
        );

        $result = DB::selectOne('SELECT @totalCount AS totalCount, @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        // Le resultset "vide" (terme introuvable) renvoie une ligne avec ProductID NULL — on la filtre.
        $items = array_values(array_filter(
            array_map(fn($row) => $row->ProductID !== null ? ProductItemDto::fromRow($row) : null, $rows)
        ));

        return new PaginatedProductItemResponseDto(
            items: $items,
            total: (int) $result->totalCount,
            page: $dto->pageNumber,
            pageSize: $dto->pageSize,
        );
    }

    public function searchProductsFullText(string $query, ?string $userPublicId): ProductSearchResultDto
    {
        $rows = DB::select(
            'CALL SP_SearchProductsFullText(?, ?, @totalCount, @success, @message)',
            [
                $query,
                $userPublicId,
            ]
        );

        $result = DB::selectOne('SELECT @totalCount AS totalCount, @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 422);
        }

        $items = array_values(array_filter(
            array_map(fn($row) => $row->ProductID !== null ? ProductItemDto::fromRow($row) : null, $rows)
        ));

        return new ProductSearchResultDto(
            items: $items,
            total: (int) $result->totalCount,
        );
    }
    public function getPublicProductInfo(int $productId): PublicProductInfoDto
    {
        $rows = DB::select('CALL SP_GetPublicProductInfo(?, @success, @message)', [
            $productId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }

        return PublicProductInfoDto::fromRow($rows[0]);
    }
    /**
     * @return ProductInfoCategoryDto[]
     */
    public function getProductCategories(int $productId): array
    {
        $rows = DB::select('CALL SP_GetProductCategories(?)', [$productId]);

        return array_map(fn($row) => ProductInfoCategoryDto::fromRow($row), $rows);
    }
    /**
     * @return ProductInfoAllowedPaymentDto[]
     */
    public function getProductAllowedPayments(int $productId): array
    {
        $rows = DB::select('CALL SP_GetProductAllowedPayments(?)', [$productId]);

        return array_map(fn($row) => ProductInfoAllowedPaymentDto::fromRow($row), $rows);
    }
    /**
     * @return ProductInfoConfigDto[]
     */
    public function getProductConfigs(int $productId): array
    {
        $rows = DB::select('CALL SP_GetProductConfigs(?)', [$productId]);

        return array_map(fn($row) => ProductInfoConfigDto::fromRow($row), $rows);
    }
    /**
     * @return ProductInfoConfigOptionDto[]
     */
    public function getProductConfigOptions(int $productId, int $configId): array
    {
        $rows = DB::select('CALL SP_GetProductConfigOptions(?, ?)', [
            $productId,
            $configId,
        ]);

        return array_map(fn($row) => ProductInfoConfigOptionDto::fromRow($row), $rows);
    }
    /**
     * @return string[]
     */
    public function getProductImages(int $productId): array
    {
        $rows = DB::select('CALL SP_GetProductImages(?)', [$productId]);

        return array_map(fn($row) => $row->ResourcesPath, $rows);
    }
    /**
     * @return ProductInfoCombinationDto[]
     */
    public function getProductCombinations(int $productId): array
    {
        $rows = DB::select('CALL SP_GetProductCombinations(?)', [$productId]);

        return array_map(fn($row) => ProductInfoCombinationDto::fromRow($row), $rows);
    }
    /**
     * @return ProductInfoCombinationConfigDto|null
     */
    public function getCombinationConfigs(int $combinationId): ?ProductInfoCombinationConfigDto
    {
        $rows = DB::select('CALL SP_GetCombinationConfigs(?)', [$combinationId]);

        if (empty($rows)) {
            return null;
        }

        return ProductInfoCombinationConfigDto::fromRow($rows[0]);
    }
    /**
     * @return ProductInfoTagDto[]
     */
    public function getProductTags(int $productId): array
    {
        $rows = DB::select('CALL SP_GetProductTags(?)', [$productId]);

        return array_map(fn($row) => ProductInfoTagDto::fromRow($row), $rows);
    }
    public function getProductPromotion(int $productId): ?ProductInfoPromotionDto
    {
        $rows = DB::select('CALL SP_GetProductPromotion(?)', [$productId]);

        if (empty($rows)) {
            return null;
        }

        return ProductInfoPromotionDto::fromRow($rows[0]);
    }
    public function hasActivePromotion(int $productId): bool
    {
        DB::select('CALL SP_HasActivePromotion(?, @found)', [$productId]);

        $result = DB::selectOne('SELECT @found AS found');

        return (bool) $result->found;
    }
    public function getSimilarProducts(int $productId, int $limit = 10): array
    {
        $rows = DB::select('CALL SP_GetSimilarProductsByName(?, ?, @success, @message)', [
            $productId,
            $limit,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        return array_map(fn($row) => PublicProductInfoDto::fromRow($row), $rows);
    }
    public function getSimilarProductsByBrandOrModel(int $productId, int $limit = 10): array
    {
        $rows = DB::select('CALL SP_GetSimilarProductsByBrandOrModel(?, ?, @success, @message)', [
            $productId,
            $limit,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        // Resultset vide filtré (cas "ni marque ni modèle" : une ligne ProductID NULL).
        return array_values(array_filter(
            array_map(
                fn($row) => $row->ProductID !== null ? PublicProductInfoDto::fromRow($row) : null,
                $rows
            )
        ));
    }
    public function getSimilarProductsByCategory(int $productId, int $limit = 10): array
    {
        $rows = DB::select('CALL SP_GetSimilarProductsByCategory(?, ?, @success, @message)', [
            $productId,
            $limit,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        // Resultset vide filtré (cas "aucune catégorie renseignée" : une ligne ProductID NULL),
        // même comportement que getSimilarProductsByBrandOrModel().
        return array_values(array_filter(
            array_map(
                fn($row) => $row->ProductID !== null ? PublicProductInfoDto::fromRow($row) : null,
                $rows
            )
        ));
    }
}
