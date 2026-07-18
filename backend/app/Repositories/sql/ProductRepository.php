<?php

namespace App\Repositories\sql;

use App\DTOs\Product\CreateProductDto;
use App\Repositories\Interface\ProductRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;

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
}