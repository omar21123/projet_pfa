<?php

namespace App\Repositories\sql;

use App\DTOs\ProductLike\AddProductLikeDto;
use App\DTOs\ProductLike\ProductLikeResultDto;
use App\DTOs\ProductLike\RemoveProductLikeDto;
use App\DTOs\ProductLike\ProductLikeDto;
use App\Repositories\Interface\ProductLikeRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;

class ProductLikeRepository implements ProductLikeRepositoryInterface
{
    public function addLike(AddProductLikeDto $dto): ProductLikeResultDto
    {
        DB::select('CALL SP_AddProductLike(?, ?, @productLikeId, @success, @message)', [
            $dto->userPublicId,
            $dto->productId,
        ]);

        $result = DB::selectOne('SELECT @productLikeId AS productLikeId, @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        return ProductLikeResultDto::fromRow($result);
    }

    public function removeLike(RemoveProductLikeDto $dto): void
    {
        DB::select('CALL SP_RemoveProductLike(?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->productId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }
    }

    public function getUserLikes(string $userPublicId): array
    {
        $pdo = DB::connection()->getPdo();

        $stmt = $pdo->prepare('CALL SP_GetUserProductLikes(?, @success, @message)');
        $stmt->bindValue(1, $userPublicId, \PDO::PARAM_STR);
        $stmt->execute();

        $rows = $stmt->fetchAll(\PDO::FETCH_OBJ);

        while ($stmt->nextRowset()) {
            // drain
        }
        $stmt->closeCursor();

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }

        return array_map(fn($row) => ProductLikeDto::fromRow($row), $rows);
    }
}