<?php

namespace App\Repositories\sql;

use App\DTOs\Wishlist\CreateWishlistDto;
use App\DTOs\Wishlist\WishlistDto;
use App\DTOs\Wishlist\WishlistItemDto;
use App\DTOs\Wishlist\AddWishlistItemDto;
use App\DTOs\Wishlist\WishlistItemResultDto;
use App\DTOs\Wishlist\RemoveWishlistItemDto;
use App\DTOs\Wishlist\DeleteWishlistDto;
use App\Repositories\Interface\WishlistRepositoryInterface;
use App\Exceptions\BusinessValidationException;
use Illuminate\Support\Facades\DB;

class WishlistRepository implements WishlistRepositoryInterface
{
    public function create(CreateWishlistDto $dto): WishlistDto
    {
        DB::select('CALL SP_CreateWishlist(?, ?, @wishListId, @success, @message)', [
            $dto->userPublicId,
            $dto->name,
        ]);

        $result = DB::selectOne('SELECT @wishListId AS wishListId, @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'introuvable') ? 404 : 422;
            throw new BusinessValidationException($result->message, $status);
        }

        $row = DB::selectOne(
            'SELECT WishListID, Name, IsDefault, CreatedAt, 0 AS ItemCount FROM WishLists WHERE WishListID = ?',
            [$result->wishListId]
        );

        return WishlistDto::fromRow($row);
    }

    public function addItem(AddWishlistItemDto $dto): WishlistItemResultDto
    {
        DB::select('CALL SP_AddWishlistItem(?, ?, ?, @wishListItemId, @success, @message)', [
            $dto->userPublicId,
            $dto->wishListId,
            $dto->productId,
        ]);

        $result = DB::selectOne('SELECT @wishListItemId AS wishListItemId, @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'Accès refusé')
                ? 403
                : (str_contains($result->message, 'introuvable') ? 404 : 422);
            throw new BusinessValidationException($result->message, $status);
        }

        return WishlistItemResultDto::fromRow($result);
    }

    public function removeItem(RemoveWishlistItemDto $dto): void
    {
        DB::select('CALL SP_RemoveWishlistItem(?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->wishListItemId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'Accès refusé')
                ? 403
                : (str_contains($result->message, 'introuvable') ? 404 : 422);
            throw new BusinessValidationException($result->message, $status);
        }
    }

    public function delete(DeleteWishlistDto $dto): void
    {
        DB::select('CALL SP_DeleteWishlist(?, ?, @success, @message)', [
            $dto->userPublicId,
            $dto->wishListId,
        ]);

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            $status = str_contains($result->message, 'Accès refusé')
                ? 403
                : (str_contains($result->message, 'introuvable') ? 404 : 422);
            throw new BusinessValidationException($result->message, $status);
        }
    }

    public function getUserWishlists(string $userPublicId): array
    {
        $pdo = DB::connection()->getPdo();

        $stmt = $pdo->prepare('CALL SP_GetUserWishlists(?, @success, @message)');
        $stmt->bindValue(1, $userPublicId, \PDO::PARAM_STR);
        $stmt->execute();

        // Resultset 1 : wishlists
        $wishlistRows = $stmt->fetchAll(\PDO::FETCH_OBJ);

        // Resultset 2 : items (toutes wishlists confondues)
        $stmt->nextRowset();
        $itemRows = $stmt->fetchAll(\PDO::FETCH_OBJ);

        while ($stmt->nextRowset()) {
            // drain
        }
        $stmt->closeCursor();

        $result = DB::selectOne('SELECT @success AS success, @message AS message');

        if (!$result->success) {
            throw new BusinessValidationException($result->message, 404);
        }

        // Regroupe les items par WishListID pour les attacher à la bonne wishlist.
        $itemsByWishlist = [];
        foreach ($itemRows as $row) {
            $itemsByWishlist[(int) $row->WishListID][] = WishlistItemDto::fromRow($row);
        }

        return array_map(
            fn($row) => WishlistDto::fromRow($row, $itemsByWishlist[(int) $row->WishListID] ?? []),
            $wishlistRows
        );
    }
}