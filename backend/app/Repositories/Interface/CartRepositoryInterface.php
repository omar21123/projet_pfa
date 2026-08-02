<?php

namespace App\Repositories\Interface;

use App\DTOs\Cart\AddCartItemDto;

interface CartRepositoryInterface
{
    public function addItem(AddCartItemDto $dto): string;
}