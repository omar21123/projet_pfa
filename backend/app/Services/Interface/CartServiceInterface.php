<?php

namespace App\Services\Interface;

use App\DTOs\Cart\AddCartItemDto;
use App\DTOs\Cart\RemoveCartItemDto;

interface CartServiceInterface
{
    public function addItem(AddCartItemDto $dto): string;
    public function removeItem(RemoveCartItemDto $dto): string;
}