<?php
// app/Repositories/Interface/PaymentRepositoryInterface.php

namespace App\Repositories\Interface;

use App\DTOs\Payment\PayFromOrderDto;
use App\DTOs\Payment\PaymentResultDto;

interface PaymentRepositoryInterface
{
    public function payFromOrder(PayFromOrderDto $dto): PaymentResultDto;
}