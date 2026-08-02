<?php

namespace App\Repositories\Interface;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Cart\RemoveCartItemDto;

interface CartRepositoryInterface
{
    public function addItem(AddCartItemDto $dto): string;
    public function removeItem(RemoveCartItemDto $dto): string;
}