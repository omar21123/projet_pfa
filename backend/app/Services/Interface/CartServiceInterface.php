<?php

namespace App\Services\Interface;

use App\DTOs\Cart\AddCartItemDto;

interface CartServiceInterface
{
    public function addItem(AddCartItemDto $dto): string;
}