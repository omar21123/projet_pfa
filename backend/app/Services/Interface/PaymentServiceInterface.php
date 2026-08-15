<?php
// app/Services/Interface/PaymentServiceInterface.php

namespace App\Services\Interface;

use App\DTOs\Payment\PayFromOrderDto;
use App\DTOs\Payment\PaymentResultDto;

interface PaymentServiceInterface
{
    public function payFromOrder(PayFromOrderDto $dto): PaymentResultDto;
}